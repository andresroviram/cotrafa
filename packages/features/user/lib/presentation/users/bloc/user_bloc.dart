import 'package:bloc/bloc.dart';
import 'package:core/errors/result.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/domain/usecases/user_usecases.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(
    this._listUsers,
    this._getUser,
    this._createClient,
    this._editUserProfile,
    this._deleteUser,
  ) : super(const UserState.initial()) {
    on<UserListRequested>(_list);
    on<UserProfileRequested>(_profile);
    on<UserSearchChanged>(_search);
    on<UserInformationRequested>(_information);
    on<UserFailureRequested>(_requestedFailure);
    on<UserCreateRequested>(_create);
    on<UserUpdateRequested>(_update);
    on<UserDeleteRequested>(_delete);
  }

  final ListUsers _listUsers;
  final GetUser _getUser;
  final CreateClient _createClient;
  final EditUserProfile _editUserProfile;
  final DeleteUser _deleteUser;

  UserState _loading() =>
      UserState.loading(users: state.users, searchQuery: state.searchQuery);

  UserState _failure(String message) => UserState.failure(
    message: message,
    users: state.users,
    searchQuery: state.searchQuery,
  );

  void _search(UserSearchChanged event, Emitter<UserState> emit) => emit(
    UserState.loaded(
      users: state.users,
      searchQuery: event.query.trim().toLowerCase(),
    ),
  );

  void _information(UserInformationRequested event, Emitter<UserState> emit) {
    if (state case UserInformation(
      message: final message,
    ) when message == event.message) {
      emit(
        UserState.loaded(users: state.users, searchQuery: state.searchQuery),
      );
    }
    emit(
      UserState.information(
        message: event.message,
        users: state.users,
        searchQuery: state.searchQuery,
      ),
    );
  }

  void _requestedFailure(UserFailureRequested event, Emitter<UserState> emit) =>
      emit(_failure(event.message));

  Future<void> _list(UserListRequested event, Emitter<UserState> emit) async {
    emit(_loading());
    final result = await _listUsers(event.actorUserId);
    emit(
      result.fold(
        onSuccess: (users) => UserState.loaded(users: users),
        onFailure: (error) => _failure(error.message),
      ),
    );
  }

  Future<void> _profile(
    UserProfileRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(_loading());
    final result = await _getUser(event.actorUserId, event.userId);
    emit(
      result.fold(
        onSuccess: (user) => UserState.loaded(users: <UserProfile>[user]),
        onFailure: (error) => _failure(error.message),
      ),
    );
  }

  Future<void> _create(
    UserCreateRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(_loading());
    final result = await _createClient(
      event.actorUserId,
      email: event.email,
      firstName: event.firstName,
      lastName: event.lastName,
      birthDate: event.birthDate,
      phone: event.phone,
      initialBalanceCop: event.initialBalanceCop,
    );
    emit(
      result.fold(
        onSuccess: (user) => UserState.created(
          users: <UserProfile>[...state.users, user],
          searchQuery: state.searchQuery,
        ),
        onFailure: (error) => _failure(error.message),
      ),
    );
  }

  Future<void> _update(
    UserUpdateRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(_loading());
    final result = await _editUserProfile(
      event.actorUserId,
      event.userId,
      firstName: event.firstName,
      lastName: event.lastName,
      birthDate: event.birthDate,
      phone: event.phone,
    );
    emit(
      result.fold(
        onSuccess: (updated) => UserState.updated(
          users: state.users
              .map((user) => user.id == updated.id ? updated : user)
              .toList(),
          searchQuery: state.searchQuery,
        ),
        onFailure: (error) => _failure(error.message),
      ),
    );
  }

  Future<void> _delete(
    UserDeleteRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(_loading());
    final deletion = await _deleteUser(event.actorUserId, event.userId);
    switch (deletion) {
      case Error(error: final error):
        emit(_failure(error.message));
      case Success(value: final outcome):
        final refreshed = await _listUsers(event.actorUserId);
        emit(
          refreshed.fold(
            onSuccess: (users) => UserState.deleted(
              users: users,
              deleteOutcome: outcome,
              searchQuery: state.searchQuery,
            ),
            onFailure: (error) => _failure(error.message),
          ),
        );
    }
  }
}
