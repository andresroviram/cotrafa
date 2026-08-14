import 'package:core/get_it.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/view/users_view.dart';
import 'package:flutter/material.dart';
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

  testWidgets('loads the correct scope from the authenticated actor', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(const UserState());
    getIt.registerFactory<UserBloc>(() => bloc);

    await tester.pumpWidget(
      MaterialApp(home: UsersView.create(actorUserId: 7, isAdmin: true)),
    );
    verify(() => bloc.add(const UserEvent.listRequested(7))).called(1);

    await tester.pumpWidget(const SizedBox());
    clearInteractions(bloc);
    await tester.pumpWidget(
      MaterialApp(home: UsersView.create(actorUserId: 8, isAdmin: false)),
    );
    verify(() => bloc.add(const UserEvent.profileRequested(8, 8))).called(1);
  });
}
