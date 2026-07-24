import 'package:flutter_bloc/flutter_bloc.dart';
import '../repo/contacts_repo.dart';

abstract class ContactsState {}
class ContactsInitial extends ContactsState {}
class ContactsLoading extends ContactsState {}
class ContactsLoaded extends ContactsState {
  final List<Map<String, dynamic>> contacts;
  final List<Map<String, dynamic>> categories;
  ContactsLoaded(this.contacts, this.categories);
}
class ContactsError extends ContactsState {
  final String message;
  ContactsError(this.message);
}

class ContactsCubit extends Cubit<ContactsState> {
  final ContactsRepo _repo;
  ContactsCubit(this._repo) : super(ContactsInitial());

  Future<void> loadContacts() async {
    emit(ContactsLoading());
    try {
      final results = await Future.wait([
        _repo.getContacts(),
        _repo.getCategories(),
      ]);
      emit(ContactsLoaded(
        results[0] as List<Map<String, dynamic>>,
        results[1] as List<Map<String, dynamic>>,
      ));
    } catch (e) {
      emit(ContactsError(e.toString()));
    }
  }
}
