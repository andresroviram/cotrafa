import 'package:bloc_test/bloc_test.dart';
import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_user/domain/entities/delete_outcome.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/domain/repository/i_user_repository.dart';
import 'package:feature_user/domain/usecases/user_usecases.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements IUserRepository {}

void main() {
  const admin = UserProfile(
    id: 1,
    email: 'admin@cotrafa.local',
    fullName: 'Admin',
    role: 'admin',
    status: 'active',
    balanceCop: 0,
  );
  const client = UserProfile(
    id: 2,
    email: 'client@example.com',
    fullName: 'Client User',
    firstName: 'Client',
    lastName: 'User',
    role: 'client',
    status: 'pendingActivation',
    balanceCop: 150000,
  );
  const updatedClient = UserProfile(
    id: 2,
    email: 'client@example.com',
    fullName: 'Updated Client',
    firstName: 'Updated',
    lastName: 'Client',
    phone: '3001234567',
    role: 'client',
    status: 'pendingActivation',
    balanceCop: 150000,
  );

  late _Repository repository;

  UserBloc build() => UserBloc(
    ListUsers(repository),
    GetUser(repository),
    CreateClient(repository),
    EditUserProfile(repository),
    DeleteUser(repository),
  );

  setUp(() => repository = _Repository());

  test('Freezed events and state preserve value semantics', () {
    const event = UserEvent.createRequested(
      1,
      email: 'client@example.com',
      firstName: 'Client',
      lastName: 'User',
      birthDate: null,
      phone: null,
      initialBalanceCop: 150000,
    );

    expect(
      event,
      const UserEvent.createRequested(
        1,
        email: 'client@example.com',
        firstName: 'Client',
        lastName: 'User',
        birthDate: null,
        phone: null,
        initialBalanceCop: 150000,
      ),
    );
    expect(
      const UserState.loaded(users: [client]).copyWith(searchQuery: 'client'),
      const UserState.loaded(users: [client], searchQuery: 'client'),
    );
    expect(
      const UserState.loaded(users: [client]).when(
        initial: (_, _) => false,
        loading: (_, _) => false,
        loaded: (_, _) => true,
        created: (_, _) => false,
        updated: (_, _) => false,
        deleted: (_, _, _) => false,
        information: (_, _, _) => false,
        failure: (_, _, _) => false,
      ),
      isTrue,
    );
  });

  blocTest<UserBloc, UserState>(
    'loads the admin user list',
    setUp: () => when(
      () => repository.listUsers(1),
    ).thenAnswer((_) async => const Success([admin, client])),
    build: build,
    act: (bloc) => bloc.add(const UserEvent.listRequested(1)),
    expect: () => const <UserState>[
      UserState.loading(),
      UserState.loaded(users: [admin, client]),
    ],
  );

  blocTest<UserBloc, UserState>(
    'loads the authenticated client profile',
    setUp: () => when(
      () => repository.getUser(2, 2),
    ).thenAnswer((_) async => const Success(client)),
    build: build,
    act: (bloc) => bloc.add(const UserEvent.profileRequested(2, 2)),
    expect: () => const <UserState>[
      UserState.loading(),
      UserState.loaded(users: [client]),
    ],
  );

  blocTest<UserBloc, UserState>(
    'stores the normalized presentation search query',
    build: build,
    act: (bloc) => bloc.add(const UserEvent.searchChanged('  Sofia  ')),
    expect: () => const <UserState>[UserState.loaded(searchQuery: 'sofia')],
  );

  blocTest<UserBloc, UserState>(
    'publishes repeated presentation notifications through state',
    build: build,
    seed: () => const UserState.information(
      message: 'user.notifications.code_error',
      users: [admin, client],
    ),
    act: (bloc) => bloc.add(
      const UserEvent.informationRequested('user.notifications.code_error'),
    ),
    expect: () => const <UserState>[
      UserState.loaded(users: [admin, client]),
      UserState.information(
        message: 'user.notifications.code_error',
        users: [admin, client],
      ),
    ],
  );

  blocTest<UserBloc, UserState>(
    'creates and updates a client without losing the loaded list',
    setUp: () {
      when(
        () => repository.createClient(
          1,
          email: 'client@example.com',
          firstName: 'Client',
          lastName: 'User',
          birthDate: null,
          phone: null,
          initialBalanceCop: 150000,
        ),
      ).thenAnswer((_) async => const Success(client));
      when(
        () => repository.editProfile(
          1,
          2,
          firstName: 'Updated',
          lastName: 'Client',
          birthDate: null,
          phone: '3001234567',
        ),
      ).thenAnswer((_) async => const Success(updatedClient));
    },
    build: build,
    seed: () => const UserState.loaded(users: [admin]),
    act: (bloc) async {
      bloc.add(
        const UserEvent.createRequested(
          1,
          email: 'client@example.com',
          firstName: 'Client',
          lastName: 'User',
          birthDate: null,
          phone: null,
          initialBalanceCop: 150000,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const UserEvent.updateRequested(
          1,
          2,
          firstName: 'Updated',
          lastName: 'Client',
          birthDate: null,
          phone: '3001234567',
        ),
      );
    },
    expect: () => const <UserState>[
      UserState.loading(users: [admin]),
      UserState.created(users: [admin, client]),
      UserState.loading(users: [admin, client]),
      UserState.updated(users: [admin, updatedClient]),
    ],
  );

  blocTest<UserBloc, UserState>(
    'deletes then reloads users from the source of truth',
    setUp: () {
      when(
        () => repository.deleteUser(1, 2),
      ).thenAnswer((_) async => const Success(DeleteOutcome.deactivated));
      when(
        () => repository.listUsers(1),
      ).thenAnswer((_) async => const Success([admin]));
    },
    build: build,
    seed: () => const UserState.loaded(users: [admin, client]),
    act: (bloc) => bloc.add(const UserEvent.deleteRequested(1, 2)),
    expect: () => const <UserState>[
      UserState.loading(users: [admin, client]),
      UserState.deleted(
        users: [admin],
        deleteOutcome: DeleteOutcome.deactivated,
      ),
    ],
  );

  blocTest<UserBloc, UserState>(
    'exposes the Result error message',
    setUp: () => when(() => repository.listUsers(1)).thenAnswer(
      (_) async => const Error(StorageFailure(message: 'SELECT users failed')),
    ),
    build: build,
    act: (bloc) => bloc.add(const UserEvent.listRequested(1)),
    expect: () => const <UserState>[
      UserState.loading(),
      UserState.failure(message: 'SELECT users failed'),
    ],
  );
}
