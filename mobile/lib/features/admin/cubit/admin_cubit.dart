import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repo/admin_repo.dart';

abstract class AdminState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<dynamic> users;
  final Map<String, dynamic> analytics;
  final List<dynamic> contacts;
  final List<dynamic> categories;
  final List<dynamic> inviteCodes;
  final List<dynamic> barangays;
  final List<dynamic> incidents;
  final List<dynamic> units;

  AdminLoaded(this.users, this.analytics, this.contacts, this.categories, [this.inviteCodes = const [], this.barangays = const [], this.incidents = const [], this.units = const []]);

  @override
  List<Object?> get props => [users, analytics, contacts, categories, inviteCodes, barangays, incidents, units];
}

class AdminError extends AdminState {
  final String message;
  final List<dynamic>? previousUsers;
  final Map<String, dynamic>? previousAnalytics;
  final List<dynamic>? previousContacts;
  final List<dynamic>? previousCategories;
  final List<dynamic>? previousInviteCodes;
  final List<dynamic>? previousBarangays;
  final List<dynamic>? previousIncidents;
  final List<dynamic>? previousUnits;

  AdminError(this.message, [this.previousUsers, this.previousAnalytics, this.previousContacts, this.previousCategories, this.previousInviteCodes, this.previousBarangays, this.previousIncidents, this.previousUnits]);

  @override
  List<Object?> get props => [message, previousUsers, previousAnalytics, previousContacts, previousCategories, previousInviteCodes, previousBarangays, previousIncidents, previousUnits];
}

class AdminCubit extends Cubit<AdminState> {
  final AdminRepo _repo;

  AdminCubit(this._repo) : super(AdminInitial());

  Future<void> loadData() async {
    emit(AdminLoading());
    try {
      final results = await Future.wait([
        _repo.getUsers(),
        _repo.getAnalytics(),
        _repo.getContacts(),
        _repo.getCategories(),
        _repo.getInviteCodes(),
        _repo.getBarangays(),
        _repo.getIncidents(),
        _repo.getUnits(),
      ]);
      emit(AdminLoaded(
        results[0] as List<dynamic>,
        results[1] as Map<String, dynamic>,
        results[2] as List<dynamic>,
        results[3] as List<dynamic>,
        results[4] as List<dynamic>,
        results[5] as List<dynamic>,
        results[6] as List<dynamic>,
        results[7] as List<dynamic>,
      ));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> updateUserRole(String id, String role) async {
    final current = state;
    List<dynamic> users = [];
    Map<String, dynamic> analytics = {};
    List<dynamic> contacts = [];
    List<dynamic> categories = [];
    List<dynamic> inviteCodes = [];
    List<dynamic> barangays = [];
    List<dynamic> incidents = [];
    List<dynamic> units = [];
    if (current is AdminLoaded) {
      users = current.users;
      analytics = current.analytics;
      contacts = current.contacts;
      categories = current.categories;
      inviteCodes = current.inviteCodes;
      barangays = current.barangays;
      incidents = current.incidents;
      units = current.units;
    }
    if (current is AdminError) {
      users = current.previousUsers ?? [];
      analytics = current.previousAnalytics ?? {};
      contacts = current.previousContacts ?? [];
      categories = current.previousCategories ?? [];
      inviteCodes = current.previousInviteCodes ?? [];
      barangays = current.previousBarangays ?? [];
      incidents = current.previousIncidents ?? [];
      units = current.previousUnits ?? [];
    }

    emit(AdminLoading());
    
    try {
      await _repo.updateUserRole(id, role);
      final updatedUsers = await _repo.getUsers();
      emit(AdminLoaded(updatedUsers, analytics, contacts, categories, inviteCodes, barangays, incidents, units));
    } catch (e) {
      emit(AdminError(e.toString(), users, analytics, contacts, categories, inviteCodes, barangays, incidents, units));
    }
  }

  Future<void> resetUserPassword(String userId, String newPassword) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.resetUserPassword(userId, newPassword);
      emit(AdminLoaded(users, analytics, contacts, categories, inviteCodes, barangays, incidents, units));
    });
  }

  Future<void> sendBroadcast(String message, {String? category, String? targetRole}) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.sendBroadcast(message, category: category, targetRole: targetRole);
      final refreshedAnalytics = await _repo.getAnalytics();
      emit(AdminLoaded(users, refreshedAnalytics, contacts, categories, inviteCodes, barangays, incidents, units));
    });
  }

  Future<void> addContact(String name, String phone, String department, String categoryId) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.addContact(name, phone, department, categoryId);
      final updatedContacts = await _repo.getContacts();
      emit(AdminLoaded(users, analytics, updatedContacts, categories, inviteCodes, barangays, incidents, units));
    });
  }

  Future<void> updateContact(String id, String name, String phone, String department, String categoryId) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.updateContact(id, name, phone, department, categoryId);
      final updatedContacts = await _repo.getContacts();
      emit(AdminLoaded(users, analytics, updatedContacts, categories, inviteCodes, barangays, incidents, units));
    });
  }

  Future<void> deleteContact(String id) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.deleteContact(id);
      final updatedContacts = contacts.where((c) => c['id'] != id).toList();
      emit(AdminLoaded(users, analytics, updatedContacts, categories, inviteCodes, barangays, incidents, units));
    });
  }

  Future<void> addCategory(String name, String icon, String color, int sortOrder) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.addCategory(name, icon, color, sortOrder);
      final updatedCats = await _repo.getCategories();
      emit(AdminLoaded(users, analytics, contacts, updatedCats, inviteCodes, barangays, incidents, units));
    });
  }

  Future<void> updateCategory(String id, String name, String icon, String color, int sortOrder) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.updateCategory(id, name, icon, color, sortOrder);
      final updatedCats = await _repo.getCategories();
      emit(AdminLoaded(users, analytics, contacts, updatedCats, inviteCodes, barangays, incidents, units));
    });
  }

  Future<void> deleteCategory(String id) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.deleteCategory(id);
      final updatedCats = categories.where((c) => c['id'] != id).toList();
      emit(AdminLoaded(users, analytics, contacts, updatedCats, inviteCodes, barangays, incidents, units));
    });
  }

  Future<void> createInviteCode(String role, {String? expiresAt}) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.createInviteCode(role, expiresAt: expiresAt);
      final newCodes = await _repo.getInviteCodes();
      emit(AdminLoaded(users, analytics, contacts, categories, newCodes, barangays, incidents, units));
    });
  }

  Future<void> deleteInviteCode(String id) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.deleteInviteCode(id);
      final newCodes = inviteCodes.where((x) => x['id'] != id).toList();
      emit(AdminLoaded(users, analytics, contacts, categories, newCodes, barangays, incidents, units));
    });
  }

  Future<void> addBarangay(String name, String? psgcCode, bool isUrban) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.addBarangay(name, psgcCode, isUrban);
      final newBarangays = await _repo.getBarangays();
      emit(AdminLoaded(users, analytics, contacts, categories, inviteCodes, newBarangays, incidents, units));
    });
  }

  Future<void> updateBarangay(String id, String name, String? psgcCode, bool isUrban) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.updateBarangay(id, name, psgcCode, isUrban);
      final newBarangays = await _repo.getBarangays();
      emit(AdminLoaded(users, analytics, contacts, categories, inviteCodes, newBarangays, incidents, units));
    });
  }

  Future<void> deleteBarangay(String id) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.deleteBarangay(id);
      final newBarangays = barangays.where((x) => x['id'] != id).toList();
      emit(AdminLoaded(users, analytics, contacts, categories, inviteCodes, newBarangays, incidents, units));
    });
  }

  Future<void> deleteIncident(String id) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.deleteIncident(id);
      final newIncidents = incidents.where((x) => x['id'].toString() != id.toString()).toList();
      final refreshed = await _repo.getAnalytics();
      emit(AdminLoaded(users, refreshed, contacts, categories, inviteCodes, barangays, newIncidents, units));
    });
  }

  Future<void> addUnit(String name, String unitType) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.addUnit(name, unitType);
      final newUnits = await _repo.getUnits();
      emit(AdminLoaded(users, analytics, contacts, categories, inviteCodes, barangays, incidents, newUnits));
    });
  }

  Future<void> updateUnitStatus(String id, String status) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.updateUnitStatus(id, status);
      final newUnits = await _repo.getUnits();
      emit(AdminLoaded(users, analytics, contacts, categories, inviteCodes, barangays, incidents, newUnits));
    });
  }

  Future<void> deleteUnit(String id) async {
    await _executeWithState((users, analytics, contacts, categories, inviteCodes, barangays, incidents, units) async {
      await _repo.deleteUnit(id);
      final newUnits = units.where((u) => u['id'] != id).toList();
      emit(AdminLoaded(users, analytics, contacts, categories, inviteCodes, barangays, incidents, newUnits));
    });
  }

  Future<String?> exportIncidents({String? dateFrom, String? dateTo, String? status, String? type}) async {
    try {
      return await _repo.exportIncidents(dateFrom: dateFrom, dateTo: dateTo, status: status, type: type);
    } catch (e) {
      return null;
    }
  }

  Future<void> _executeWithState(
    Future<void> Function(List<dynamic> users, Map<String, dynamic> analytics, List<dynamic> contacts, List<dynamic> categories, List<dynamic> inviteCodes, List<dynamic> barangays, List<dynamic> incidents, List<dynamic> units) action
  ) async {
    final current = state;
    List<dynamic> users = [];
    Map<String, dynamic> analytics = {};
    List<dynamic> contacts = [];
    List<dynamic> categories = [];
    List<dynamic> inviteCodes = [];
    List<dynamic> barangays = [];
    List<dynamic> incidents = [];
    List<dynamic> units = [];
    if (current is AdminLoaded) {
      users = current.users;
      analytics = current.analytics;
      contacts = current.contacts;
      categories = current.categories;
      inviteCodes = current.inviteCodes;
      barangays = current.barangays;
      incidents = current.incidents;
      units = current.units;
    } else if (current is AdminError) {
      users = current.previousUsers ?? [];
      analytics = current.previousAnalytics ?? {};
      contacts = current.previousContacts ?? [];
      categories = current.previousCategories ?? [];
      inviteCodes = current.previousInviteCodes ?? [];
      barangays = current.previousBarangays ?? [];
      incidents = current.previousIncidents ?? [];
      units = current.previousUnits ?? [];
    }

    if (current is! AdminLoaded && current is! AdminError) {
      emit(AdminLoading());
    }
    try {
      await action(users, analytics, contacts, categories, inviteCodes, barangays, incidents, units);
    } catch (e) {
      emit(AdminError(e.toString(), users, analytics, contacts, categories, inviteCodes, barangays, incidents, units));
    }
  }
}
