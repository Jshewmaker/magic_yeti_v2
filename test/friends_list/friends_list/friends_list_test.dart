import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list/bloc/friend_list_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list/friends_list.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:user_repository/user_repository.dart';

import '../../helpers/pump_app.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

void main() {
  group('FriendsListView block action', () {
    late MockAppBloc appBloc;
    late MockFriendBloc friendBloc;

    const bob = FriendModel(
      userId: 'bob',
      username: 'Bob',
      profilePictureUrl: 'http://x/bob.png',
      friendCode: 'YETI-B0B1',
    );

    setUp(() {
      appBloc = MockAppBloc();
      friendBloc = MockFriendBloc();
      when(() => appBloc.state).thenReturn(
        const AppState.authenticated(User(id: 'alice')),
      );
      when(() => friendBloc.state).thenReturn(const FriendsLoaded([bob]));
    });

    Future<void> pumpFriendsList(WidgetTester tester) async {
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<FriendBloc>.value(value: friendBloc),
          ],
          child: const FriendsListView(),
        ),
      );
      await tester.pump();
    }

    testWidgets('exposes a Block action in the friend card menu',
        (tester) async {
      await pumpFriendsList(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Block'), findsOneWidget);
    });

    testWidgets(
        'confirming Block dispatches BlockFriend with the built '
        'BlockedUserModel', (tester) async {
      await pumpFriendsList(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      // Confirmation dialog action button (also labelled "Block").
      await tester.tap(find.text('Block').last);
      await tester.pumpAndSettle();

      verify(
        () => friendBloc.add(
          const BlockFriend(
            'alice',
            BlockedUserModel(
              userId: 'bob',
              username: 'Bob',
              imageUrl: 'http://x/bob.png',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets(
        'confirming Remove renders localized dialog copy and dispatches '
        'RemoveFriend', (tester) async {
      await pumpFriendsList(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(FriendsListView)),
      );
      expect(find.text(l10n.removeFriendConfirmTitle('Bob')), findsOneWidget);
      expect(find.text(l10n.removeFriendConfirmBody), findsOneWidget);
      expect(find.text(l10n.cancelTextButton), findsOneWidget);

      // Confirmation dialog action button (also labelled "Remove").
      await tester.tap(find.text('Remove').last);
      await tester.pumpAndSettle();

      verify(
        () => friendBloc.add(const RemoveFriend('alice', 'bob')),
      ).called(1);
    });
  });
}
