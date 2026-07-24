import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repo/dispatcher_repo.dart';

abstract class DispatcherState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DispatcherInitial extends DispatcherState {}
class DispatcherLoading extends DispatcherState {}
class QueueLoaded extends DispatcherState {
  final List<dynamic> incidents;
  QueueLoaded(this.incidents);
  @override
  List<Object?> get props => [incidents];
}
class IncidentUpdating extends DispatcherState {
  final List<dynamic> incidents;
  final String updatingId;
  IncidentUpdating(this.incidents, this.updatingId);
  @override
  List<Object?> get props => [incidents, updatingId];
}
class DispatcherError extends DispatcherState {
  final String message;
  final List<dynamic>? incidents;
  DispatcherError(this.message, [this.incidents]);
  @override
  List<Object?> get props => [message, incidents];
}

class DashboardLoaded extends DispatcherState {
  final List<dynamic> incidents;
  final int total;
  final int submitted;
  final int underReview;
  final int verified;
  final int rejected;
  final int resolved;
  final int critical;
  final List<dynamic> recentCritical;
  DashboardLoaded({
    required this.incidents,
    required this.total,
    required this.submitted,
    required this.underReview,
    required this.verified,
    required this.rejected,
    required this.resolved,
    required this.critical,
    required this.recentCritical,
  });
  @override
  List<Object?> get props => [total, submitted, underReview, verified, rejected, resolved, critical];
}

class DispatcherCubit extends Cubit<DispatcherState> {
  final DispatcherRepo _repo;
  DispatcherCubit(this._repo) : super(DispatcherInitial());

  List<dynamic> get _currentIncidents {
    final s = state;
    if (s is QueueLoaded) return s.incidents;
    if (s is IncidentUpdating) return s.incidents;
    if (s is DispatcherError) return s.incidents ?? [];
    if (s is DashboardLoaded) return s.incidents;
    return [];
  }

  Future<void> loadDashboard() async {
    emit(DispatcherLoading());
    try {
      final incidents = await _repo.getQueue();
      final sorted = List<Map<String, dynamic>>.from(incidents).toList();
      emit(DashboardLoaded(
        incidents: incidents,
        total: incidents.length,
        submitted: incidents.where((i) => i['status'] == 'submitted').length,
        underReview: incidents.where((i) => i['status'] == 'under_review').length,
        verified: incidents.where((i) => i['status'] == 'verified').length,
        rejected: incidents.where((i) => i['status'] == 'rejected').length,
        resolved: incidents.where((i) => i['status'] == 'resolved').length,
        critical: incidents.where((i) => i['severity'] == 'critical').length,
        recentCritical: sorted
          ..sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''))
          ..retainWhere((i) => i['severity'] == 'critical'),
      ));
    } catch (e) {
      emit(DispatcherError(e.toString()));
    }
  }

  Future<void> loadQueue({String? status}) async {
    emit(DispatcherLoading());
    try {
      final incidents = await _repo.getQueue(status: status);
      emit(QueueLoaded(incidents));
    } catch (e) {
      emit(DispatcherError(e.toString()));
    }
  }

  Future<void> searchIncidents({
    String? query,
    String? status,
    String? type,
    String? barangayId,
  }) async {
    emit(DispatcherLoading());
    try {
      final incidents = await _repo.searchIncidents(
        query: query,
        status: status,
        type: type,
        barangayId: barangayId,
      );
      emit(QueueLoaded(incidents));
    } catch (e) {
      emit(DispatcherError(e.toString()));
    }
  }

  Future<void> verifyIncident(String id, {String? severity, String? note}) async {
    final current = _currentIncidents;
    emit(IncidentUpdating(current, id));
    try {
      final updated = await _repo.verifyIncident(id, severity: severity, note: note);
      final incidents = current.map((i) => i['id'] == id ? updated : i).toList();
      emit(QueueLoaded(incidents));
    } catch (e) {
      emit(DispatcherError(e.toString(), current));
    }
  }

  Future<void> rejectIncident(String id, String reason) async {
    final current = _currentIncidents;
    emit(IncidentUpdating(current, id));
    try {
      final updated = await _repo.rejectIncident(id, reason);
      final incidents = current.map((i) => i['id'] == id ? updated : i).toList();
      emit(QueueLoaded(incidents));
    } catch (e) {
      emit(DispatcherError(e.toString(), current));
    }
  }

  Future<void> updateStatus(String id, String status) async {
    final current = _currentIncidents;
    emit(IncidentUpdating(current, id));
    try {
      final updated = await _repo.updateStatus(id, status);
      final incidents = current.map((i) => i['id'] == id ? updated : i).toList();
      emit(QueueLoaded(incidents));
    } catch (e) {
      emit(DispatcherError(e.toString(), current));
    }
  }
}