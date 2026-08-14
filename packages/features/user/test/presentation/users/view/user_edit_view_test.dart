import 'package:core/get_it.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/view/user_edit_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

final class _MockUserBloc extends Mock implements UserBloc {}

void main() {
  setUpAll(() => registerFallbackValue(const UserEvent.listRequested(0)));

  late _MockUserBloc bloc;

  setUp(() {
    bloc = _MockUserBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream<UserState>.empty());
    when(() => bloc.add(any())).thenReturn(null);
    when(() => bloc.close()).thenAnswer((_) async {});
  });

  tearDown(() async => getIt.reset());

  Widget app(Widget home) => MaterialApp(home: home);

  testWidgets('loads the requested user when the full route opens', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(const UserState());
    getIt.registerFactory<UserBloc>(() => bloc);

    await tester.pumpWidget(
      app(UserEditView.create(actorUserId: 1, userId: 2)),
    );

    verify(() => bloc.add(const UserEvent.profileRequested(1, 2))).called(1);
  });

  testWidgets('edits optional personal data and keeps email read-only', (
    tester,
  ) async {
    final user = UserProfile(
      id: 2,
      email: 'sofia@cotrafa.local',
      fullName: 'Sofia Rovira',
      firstName: 'Sofia',
      lastName: 'Rovira',
      birthDate: DateTime(2000, 6, 15),
      phone: '3000000000',
      role: 'client',
      status: 'active',
      balanceCop: 250000,
    );
    when(
      () => bloc.state,
    ).thenReturn(UserState(status: UserStatus.loaded, users: [user]));

    await tester.pumpWidget(
      app(
        BlocProvider<UserBloc>.value(
          value: bloc,
          child: const UserEditView(actorUserId: 1, userId: 2),
        ),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Editar usuario'), findsOneWidget);
    final email = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('edit-user-email')),
        matching: find.byType(TextField),
      ),
    );
    expect(email.readOnly, isTrue);
    expect(email.controller?.text, user.email);

    await tester.enterText(
      find.byKey(const Key('edit-user-first-name')),
      'Sofía',
    );
    await tester.enterText(
      find.byKey(const Key('edit-user-last-name')),
      'Rovira Gómez',
    );
    await tester.enterText(
      find.byKey(const Key('edit-user-phone')),
      '3012345678',
    );
    await tester.tap(find.byKey(const Key('edit-user-submit')));
    await tester.pump();

    verify(
      () => bloc.add(
        UserEvent.updateRequested(
          1,
          2,
          firstName: 'Sofía',
          lastName: 'Rovira Gómez',
          birthDate: DateTime(2000, 6, 15),
          phone: '3012345678',
        ),
      ),
    ).called(1);
  });
}
