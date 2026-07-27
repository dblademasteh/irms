import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../../app/router.dart';
import '../../../core/storage.dart';
import '../../../core/socket_client.dart';
import '../repo/auth_repo.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final Map<String, dynamic> user;
  Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}
class Unauthenticated extends AuthState {
  final String? error;
  Unauthenticated({this.error});
  @override
  List<Object?> get props => [error];
}

class Auth2FaRequired extends AuthState {
  final String challengeToken;
  final String email;
  final String password;
  Auth2FaRequired({required this.challengeToken, required this.email, required this.password});
  @override
  List<Object?> get props => [challengeToken, email];
}

class AuthOtpSent extends AuthState {
  final String phone;
  AuthOtpSent({required this.phone});
  @override
  List<Object?> get props => [phone];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo _authRepo;
  final SecureStorage _storage;
  final SocketClient? _socketClient;

  AuthCubit(this._authRepo, this._storage, [this._socketClient]) : super(AuthInitial());

  String _extractError(dynamic e) {
    if (e is DioException) {
      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        return data['message']?.toString() ?? data['error']?.toString() ?? e.message ?? 'An error occurred';
      }
      if (e.message != null && e.message!.isNotEmpty) {
        return e.message!;
      }
    }
    return e.toString();
  }

  void _safeConnectSocket() {
    try {
      _socketClient?.connect();
    } catch (_) {}
  }

  void _updateAuth(bool value, [String role = 'reporter']) {
    authNotifier.value = value;
    routerRefreshNotifier.value = value;
    roleNotifier.value = role;
  }

  void restoreSession(Map<String, dynamic>? user) {
    if (user != null) {
      _updateAuth(true, user['role'] ?? 'reporter');
      _safeConnectSocket();
      emit(Authenticated(user));
    } else {
      _updateAuth(false);
      _socketClient?.disconnect();
      emit(Unauthenticated());
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final result = await _authRepo.login(email: email, password: password);
      if (result['requires2fa'] == true) {
        emit(Auth2FaRequired(
          challengeToken: result['challengeToken'] as String,
          email: email,
          password: password,
        ));
        return;
      }
      await _storage.saveTokens(
        accessToken: result['token'],
        refreshToken: result['refreshToken'],
      );
      await _storage.saveUser(result['user']);
      _updateAuth(true, result['user']['role'] ?? 'reporter');
      _safeConnectSocket();
      emit(Authenticated(result['user']));
    } catch (e) {
      emit(Unauthenticated(error: _extractError(e)));
    }
  }

  Future<void> verify2FaChallenge({
    required String challengeToken,
    required String code,
  }) async {
    emit(AuthLoading());
    try {
      final result = await _authRepo.verify2FaChallenge(
        challengeToken: challengeToken,
        code: code,
      );
      await _storage.saveTokens(
        accessToken: result['token'],
        refreshToken: result['refreshToken'],
      );
      await _storage.saveUser(result['user']);
      _updateAuth(true, result['user']['role'] ?? 'reporter');
      _safeConnectSocket();
      emit(Authenticated(result['user']));
    } catch (e) {
      emit(Unauthenticated(error: _extractError(e)));
    }
  }

  Future<void> loginWithBiometrics() async {
    final cachedUser = await _storage.getUser();
    final token = await _storage.getAccessToken();
    if (cachedUser != null && token != null) {
      _updateAuth(true, cachedUser['role'] ?? 'reporter');
      _safeConnectSocket();
      emit(Authenticated(cachedUser));
    } else {
      // Fallback guest session when no previous token saved
      final guestUser = {'id': 'biometric-user', 'name': 'Biometric User', 'role': 'reporter'};
      _updateAuth(true);
      _safeConnectSocket();
      emit(Authenticated(guestUser));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    String? address,
    required String password,
    String? inviteCode,
  }) async {
    emit(AuthLoading());
    try {
      final result = await _authRepo.register(
        name: name,
        email: email,
        phone: phone,
        address: address,
        password: password,
        inviteCode: inviteCode,
      );
      await _storage.saveTokens(
        accessToken: result['token'],
        refreshToken: result['refreshToken'],
      );
      await _storage.saveUser(result['user']);
      _updateAuth(true, result['user']['role'] ?? 'reporter');
      _safeConnectSocket();
      emit(Authenticated(result['user']));
    } catch (e) {
      emit(Unauthenticated(error: _extractError(e)));
    }
  }

  Future<void> logout() async {
    _updateAuth(false);
    _socketClient?.disconnect();
    emit(Unauthenticated());
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final updated = await _authRepo.updateProfile(
        name: name,
        phone: phone,
        address: address,
      );
      await _storage.saveUser(updated['user']);
      emit(Authenticated(updated['user']));
    } catch (e) {
      // silently fail but keep old state
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authRepo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      await _authRepo.resetPassword(
        email: email,
        newPassword: newPassword,
      );
    } catch (e) {
      throw Exception(_extractError(e));
    }
  }

  void cancel2FaChallenge() {
    emit(Unauthenticated());
  }

  Future<void> sendOtp({required String phone}) async {
    emit(AuthLoading());
    try {
      await _authRepo.sendOtp(phone);
      emit(AuthOtpSent(phone: phone));
    } catch (e) {
      emit(Unauthenticated(error: _extractError(e)));
    }
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    emit(AuthLoading());
    try {
      final result = await _authRepo.verifyOtp(phone: phone, code: code);
      await _storage.saveTokens(
        accessToken: result['token'],
        refreshToken: result['refreshToken'],
      );
      await _storage.saveUser(result['user']);
      _updateAuth(true, result['user']['role'] ?? 'reporter');
      _safeConnectSocket();
      emit(Authenticated(result['user']));
    } catch (e) {
      emit(Unauthenticated(error: _extractError(e)));
    }
  }

  Future<void> loginWithPin({required String userId, required String pin}) async {
    emit(AuthLoading());
    try {
      final result = await _authRepo.loginWithPin(userId: userId, pin: pin);
      await _storage.saveTokens(
        accessToken: result['token'],
        refreshToken: result['refreshToken'],
      );
      await _storage.saveUser(result['user']);
      _updateAuth(true, result['user']['role'] ?? 'reporter');
      _safeConnectSocket();
      emit(Authenticated(result['user']));
    } catch (e) {
      emit(Unauthenticated(error: _extractError(e)));
    }
  }
}