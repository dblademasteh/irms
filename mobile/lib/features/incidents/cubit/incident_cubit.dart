import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repo/incident_repo.dart';

abstract class IncidentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class IncidentInitial extends IncidentState {}
class IncidentSubmitting extends IncidentState {}
class IncidentSubmitted extends IncidentState {
  final Map<String, dynamic> incident;
  IncidentSubmitted(this.incident);
  @override
  List<Object?> get props => [incident];
}
class IncidentsLoaded extends IncidentState {
  final List<dynamic> incidents;
  IncidentsLoaded(this.incidents);
  @override
  List<Object?> get props => [incidents];
}
class IncidentDetailLoaded extends IncidentState {
  final Map<String, dynamic> incident;
  IncidentDetailLoaded(this.incident);
  @override
  List<Object?> get props => [incident];
}
class IncidentTracked extends IncidentState {
  final Map<String, dynamic> incident;
  IncidentTracked(this.incident);
  @override
  List<Object?> get props => [incident];
}
class IncidentError extends IncidentState {
  final String message;
  IncidentError(this.message);
  @override
  List<Object?> get props => [message];
}

class IncidentCubit extends Cubit<IncidentState> {
  final IncidentRepo _repo;
  IncidentCubit(this._repo) : super(IncidentInitial());

  Future<void> submitIncident({
    required String type,
    required String title,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    String? reporterPhone,
    String? barangayId,
    List<Uint8List>? photoBytesList,
  }) async {
    emit(IncidentSubmitting());
    try {
      List<String> mediaIds = [];
      if (photoBytesList != null && photoBytesList.isNotEmpty) {
        for (final bytes in photoBytesList) {
          final mediaId = await _repo.uploadMedia(bytes);
          if (mediaId != null) mediaIds.add(mediaId);
        }
      }
      final incident = await _repo.createIncident(
        type: type,
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        address: address,
        reporterPhone: reporterPhone,
        barangayId: barangayId,
        mediaIds: mediaIds.isNotEmpty ? mediaIds : null,
      );
      emit(IncidentSubmitted(incident));
    } catch (e) {
      emit(IncidentError(e.toString()));
    }
  }

  Future<void> loadMyReports({String? status}) async {
    try {
      final incidents = await _repo.getMine(status: status);
      emit(IncidentsLoaded(incidents));
    } catch (e) {
      emit(IncidentError(e.toString()));
    }
  }

  Future<void> loadDetail(String id) async {
    try {
      final incident = await _repo.getById(id);
      emit(IncidentDetailLoaded(incident));
    } catch (e) {
      emit(IncidentError(e.toString()));
    }
  }

  Future<void> trackByCode(String code) async {
    emit(IncidentSubmitting());
    try {
      final incident = await _repo.trackByCode(code);
      emit(IncidentTracked(incident));
    } catch (e) {
      emit(IncidentError(e.toString()));
    }
  }

  void reset() => emit(IncidentInitial());
}
