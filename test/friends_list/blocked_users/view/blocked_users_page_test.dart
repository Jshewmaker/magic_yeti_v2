import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/blocked_users/bloc/blocked_users_bloc.dart';
import 'package:magic_yeti/friends_list/blocked_users/view/blocked_users_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:user_repository/user_repository.dart';

import '../../../helpers/pump_app.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockBlockedUsersBloc
    extends MockBloc<BlockedUsersEvent, BlockedUsersState>
    implements BlockedUsersBloc {}

void main() {
  group('BlockedUsersView', () {
    late MockAppBloc appBloc;
    late MockBlockedUsersBloc blockedUsersBloc;

    const bob = BlockedUserModel(
      userId: 'bob',
      username: 'Bob',
      imageUrl: 'http://x/bob.png',
    );
    const carol = BlockedUserModel(
      userId: 'carol',
      username: 'Carol',
      imageUrl: 'http://x/carol.png',
    );

    setUp(() {
      appBloc = MockAppBloc();
      blockedUsersBloc = MockBlockedUsersBloc();
      when(() => appBloc.state).thenReturn(
        const AppState.authenticated(User(id: 'alice')),
      );
    });

    Future<void> pumpBlockedUsers(WidgetTester tester) async {
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<BlockedUsersBloc>.value(value: blockedUsersBloc),
          ],
          child: const BlockedUsersView(),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders seeded blocked users', (tester) async {
      when(() => blockedUsersBloc.state)
          .thenReturn(const BlockedUsersLoaded([bob, carol]));

      await pumpBlockedUsers(tester);

      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
    });

    testWidgets('shows the empty state when there are no blocked users',
        (tester) async {
      when(() => blockedUsersBloc.state)
          .thenReturn(const BlockedUsersLoaded([]));

      await pumpBlockedUsers(tester);

      expect(find.text("You haven't blocked anyone."), findsOneWidget);
    });

    testWidgets('shows a loading indicator while loading', (tester) async {
      when(() => blockedUsersBloc.state).thenReturn(BlockedUsersLoading());

      await pumpBlockedUsers(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('tapping unblock and confirming dispatches UnblockUser',
        (tester) async {
      when(() => blockedUsersBloc.state)
          .thenReturn(const BlockedUsersLoaded([bob]));

      await pumpBlockedUsers(tester);

      await tester.tap(find.text('Unblock'));
      await tester.pumpAndSettle();

      // Confirm in the dialog (second "Unblock", the action button).
      await tester.tap(find.text('Unblock').last);
      await tester.pumpAndSettle();

      verify(
        () => blockedUsersBloc.add(const UnblockUser('alice', 'bob')),
      ).called(1);
    });
  });
}
