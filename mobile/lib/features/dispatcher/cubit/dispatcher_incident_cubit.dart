import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repo/dispatcher_repo.dart';

abstract class DispatcherIncidentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DispatcherIncidentInitial extends DispatcherIncidentState {}

class DispatcherIncidentLoading extends DispatcherIncidentState {}

class DispatcherIncidentLoaded extends DispatcherIncidentState {
  final Map<String, dynamic> incident;
  final String currentUserId;

  DispatcherIncidentLoaded(this.incident, this.currentUserId);

  @override
  List<Object?> get props => [incident, currentUserId];
}

class DispatcherIncidentError extends DispatcherIncidentState {
  final String message;
  final Map<String, dynamic>? previousIncident;
  final String? currentUserId;

  DispatcherIncidentError(this.message, [this.previousIncident, this.currentUserId]);

  @override
  List<Object?> get props => [message, previousIncident, currentUserId];
}

class DispatcherIncidentCubit extends Cubit<DispatcherIncidentState> {
  final DispatcherRepo _repo;
  final String currentUserId;
  final String incidentId;
  List<dynamic> _units = [];

  DispatcherIncidentCubit(this._repo, {required this.currentUserId, required this.incidentId}) 
    : super(DispatcherIncidentInitial());

  List<dynamic> get units => _units;

  Future<void> loadIncident() async {
    emit(DispatcherIncidentLoading());
    try {
      final results = await Future.wait([
        _repo.getIncidentDetails(incidentId),
        _repo.getIncidentUnits(incidentId),
      ]);
      final incident = results[0] as Map<String, dynamic>;
      _units = results[1] as List<dynamic>;
      emit(DispatcherIncidentLoaded(incident, currentUserId));
    } catch (e) {
      emit(DispatcherIncidentError(e.toString()));
    }
  }

  Future<void> claimIncident() async {
    _updateOptimistic((_) => emit(DispatcherIncidentLoading()));
    try {
      await _repo.updateStatus(incidentId, 'under_review');
      await loadIncident();
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> verifyIncident(String severity, String note) async {
    _updateOptimistic((_) => emit(DispatcherIncidentLoading()));
    try {
      await _repo.verifyIncident(incidentId, severity: severity, note: note);
      await loadIncident();
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> rejectIncident(String reason) async {
    _updateOptimistic((_) => emit(DispatcherIncidentLoading()));
    try {
      await _repo.rejectIncident(incidentId, reason);
      await loadIncident();
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> declineIncident(String reason) async {
    _updateOptimistic((_) => emit(DispatcherIncidentLoading()));
    try {
      await _repo.declineIncident(incidentId, reason);
      await loadIncident();
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> resolveIncident(String notes) async {
    _updateOptimistic((_) => emit(DispatcherIncidentLoading()));
    try {
      await _repo.resolveIncident(incidentId, notes: notes);
      await loadIncident();
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> dispatchUnits(List<String> unitIds) async {
    try {
      await _repo.dispatchUnits(incidentId, unitIds);
      await loadIncident();
    } catch (e) {
      _emitError(e.toString());
    }
  }

  Future<void> removeUnit(String unitId) async {
    try {
      await _repo.removeUnitFromIncident(incidentId, unitId);
      _units = _units.where((u) => u['unit_id'] != unitId).toList();
      if (state is DispatcherIncidentLoaded) {
        emit(DispatcherIncidentLoaded(
          (state as DispatcherIncidentLoaded).incident,
          currentUserId,
        ));
      }
    } catch (e) {
      _emitError(e.toString());
    }
  }

  void updateUnits(List<dynamic> newUnits) {
    _units = newUnits;
    if (state is DispatcherIncidentLoaded) {
      emit(DispatcherIncidentLoaded(
        (state as DispatcherIncidentLoaded).incident,
        currentUserId,
      ));
    }
  }

  void _updateOptimistic(void Function(Map<String, dynamic>?) action) {
    if (state is DispatcherIncidentLoaded) {
      action((state as DispatcherIncidentLoaded).incident);
    } else if (state is DispatcherIncidentError) {
      action((state as DispatcherIncidentError).previousIncident);
    } else {
      action(null);
    }
  }

  void _emitError(String msg) {
    if (state is DispatcherIncidentLoaded) {
      emit(DispatcherIncidentError(msg, (state as DispatcherIncidentLoaded).incident, currentUserId));
    } else if (state is DispatcherIncidentError) {
      emit(DispatcherIncidentError(msg, (state as DispatcherIncidentError).previousIncident, currentUserId));
    } else {
      emit(DispatcherIncidentError(msg));
    }
  }
}
