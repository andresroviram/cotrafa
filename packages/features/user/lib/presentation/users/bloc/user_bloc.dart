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
  ) : super(const UserState()) {
    on<UserListRequested>(_list);
    on<UserProfileRequested>(_profile);
    on<UserSearchChanged>(_search);
    on<UserNotificationRequested>(_notification);
    on<UserCreateRequested>(_create);
    on<UserUpdateRequested>(_update);
    on<UserDeleteRequested>(_delete);
  }

  final ListUsers _listUsers;
  final GetUser _getUser;
  final CreateClient _createClient;
  final EditUserProfile _editUserProfile;
  final DeleteUser _deleteUser;

  UserState _loading() => state.copyWith(
    status: UserStatus.loading,
    deleteOutcome: null,
    message: null,
  );

  UserState _failure(String message) => state.copyWith(
    status: UserStatus.failure,
    deleteOutcome: null,
    message: message,
  );

  void _search(UserSearchChanged event, Emitter<UserState> emit) =>
      emit(state.copyWith(searchQuery: event.query.trim().toLowerCase()));

  void _notification(UserNotificationRequested event, Emitter<UserState> emit) {
    if (state.message == event.message &&
        state.notificationType == event.type) {
      emit(state.copyWith(message: null));
    }
    emit(state.copyWith(message: event.message, notificationType: event.type));
  }

  Future<void> _list(UserListRequested event, Emitter<UserState> emit) async {
    emit(_loading());
    final result = await _listUsers(event.actorUserId);
    emit(
      result.fold(
        onSuccess: (users) =>
            UserState(status: UserStatus.loaded, users: users),
        onFailure: (_) => _failure('user.errors.load_list'),
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
        onSuccess: (user) =>
            UserState(status: UserStatus.loaded, users: <UserProfile>[user]),
        onFailure: (_) => _failure('user.errors.load_profile'),
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
        onSuccess: (user) => state.copyWith(
          status: UserStatus.created,
          users: <UserProfile>[...state.users, user],
        ),
        onFailure: (_) => _failure('user.errors.create'),
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
        onSuccess: (updated) => state.copyWith(
          status: UserStatus.updated,
          users: state.users
              .map((user) => user.id == updated.id ? updated : user)
              .toList(),
        ),
        onFailure: (_) => _failure('user.errors.update'),
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
      case Error():
        emit(_failure('user.errors.delete'));
      case Success(value: final outcome):
        final refreshed = await _listUsers(event.actorUserId);
        emit(
          refreshed.fold(
            onSuccess: (users) => UserState(
              status: UserStatus.deleted,
              users: users,
              deleteOutcome: outcome,
            ),
            onFailure: (_) => _failure('user.errors.reload'),
          ),
        );
    }
  }
}
