import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/view/user_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:responsive_framework/responsive_framework.dart';

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

  Widget subject(UserProfile user) {
    when(
      () => bloc.state,
    ).thenReturn(UserState(status: UserStatus.loaded, users: [user]));
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF004183),
          foregroundColor: Colors.white,
        ),
      ),
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
        ],
      ),
      home: BlocProvider<UserBloc>.value(
        value: bloc,
        child: UserDetailView(actorUserId: 1, userId: user.id),
      ),
    );
  }

  testWidgets('copies the reference detail hierarchy with optional data', (
    tester,
  ) async {
    final user = UserProfile(
      id: 2,
      email: 'sofia@cotrafa.local',
      fullName: 'Sofia Rovira',
      firstName: 'Sofia',
      lastName: 'Rovira',
      birthDate: DateTime(2000, 8, 14),
      phone: '3001234567',
      role: 'client',
      status: 'active',
      balanceCop: 250000,
    );

    await tester.pumpWidget(subject(user));

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverAppBar), findsOneWidget);
    final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    expect(appBar.backgroundColor, const Color(0xFF004183));
    final header = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(FlexibleSpaceBar),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((header.decoration as BoxDecoration).color, const Color(0xFF004183));
    expect(find.text('Sofia Rovira'), findsOneWidget);
    expect(find.text('Información personal'), findsOneWidget);
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Sofia'), findsOneWidget);
    expect(find.text('Apellido'), findsOneWidget);
    expect(find.text('Rovira'), findsOneWidget);
    expect(find.text('Fecha de nacimiento'), findsOneWidget);
    expect(find.text('14/08/2000'), findsOneWidget);
    expect(find.text('Edad'), findsOneWidget);
    expect(find.textContaining('años'), findsOneWidget);
    expect(find.text('Contacto'), findsOneWidget);
    expect(find.text('300 123 4567'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Editar'), findsOneWidget);
    expect(find.text('Direcciones'), findsOneWidget);

    await tester.tap(find.text('Direcciones'));
    await tester.pump();
    verify(
      () => bloc.add(
        const UserEvent.notificationRequested(
          'La gestión de direcciones estará disponible próximamente',
          type: UserNotificationType.info,
        ),
      ),
    ).called(1);
  });

  testWidgets('shows safe placeholders for missing optional data', (
    tester,
  ) async {
    const user = UserProfile(
      id: 2,
      email: 'client@cotrafa.local',
      fullName: '',
      role: 'client',
      status: 'active',
      balanceCop: 0,
    );

    await tester.pumpWidget(subject(user));

    expect(find.text('client@cotrafa.local'), findsWidgets);
    expect(find.text('Sin registrar'), findsNWidgets(5));
  });

  testWidgets('shows available balance and opens the shared edit modal', (
    tester,
  ) async {
    const user = UserProfile(
      id: 2,
      email: 'client@cotrafa.local',
      fullName: 'Client User',
      firstName: 'Client',
      lastName: 'User',
      role: 'client',
      status: 'active',
      balanceCop: 250000,
    );

    await tester.pumpWidget(subject(user));

    expect(find.byKey(const Key('user-available-balance')), findsOneWidget);
    expect(find.text('Saldo disponible'), findsOneWidget);
    expect(find.textContaining('250.000'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('user-available-balance'))).dy,
      lessThan(
        tester.getTopLeft(find.widgetWithText(FilledButton, 'Editar')).dy,
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar usuario'), findsOneWidget);
    expect(find.byKey(const Key('edit-user-first-name')), findsOneWidget);
    expect(find.byKey(const Key('edit-user-last-name')), findsOneWidget);
    expect(find.byKey(const Key('edit-user-email')), findsOneWidget);
    expect(find.byKey(const Key('create-user-balance')), findsNothing);
  });
}
