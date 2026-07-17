import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list/bloc/friend_list_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list_page.dart';
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:user_repository/user_repository.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockFriendRequestBloc
    extends MockBloc<FriendRequestEvent, FriendRequestState>
    implements FriendRequestBloc {}

class _MockFriendBloc extends MockBloc<FriendEvent, FriendState>
    implements FriendBloc {}

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  late AppBloc appBloc;
  late FriendRequestBloc friendRequestBloc;
  late FriendBloc friendBloc;
  late FirebaseDatabaseRepository databaseRepository;

  final request = FriendRequestModel(
    id: 'bob_alice',
    senderId: 'bob',
    senderName: 'Bob',
    receiverId: 'alice',
    status: 'pending',
    timestamp: DateTime(2024),
  );

  setUp(() {
    appBloc = _MockAppBloc();
    friendRequestBloc = _MockFriendRequestBloc();
    friendBloc = _MockFriendBloc();
    databaseRepository = _MockFirebaseDatabaseRepository();

    when(() => appBloc.state).thenReturn(
      const AppState.authenticated(User(id: 'alice')),
    );
    when(() => friendBloc.state).thenReturn(const FriendsLoaded([]));
    // The Friends tab (index 0) is always the initially-visible TabBarView
    // page, so its body — FriendsList — really builds on every pump here.
    // FriendsList creates its own real FriendBloc rather than reading the
    // one provided above (see friends_list.dart), and that bloc calls this
    // repository method immediately via LoadFriends. Unrelated to the
    // Requests-tab badge under test, but must be stubbed or the unmocked
    // call throws and fails the test.
    when(() => databaseRepository.watchFriends(any()))
        .thenAnswer((_) => const Stream.empty());
  });

  Widget buildSubject() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: databaseRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: appBloc),
            BlocProvider.value(value: friendRequestBloc),
            BlocProvider.value(value: friendBloc),
          ],
          child: const FriendsListPage(),
        ),
      ),
    );
  }

  group('FriendsListPage', () {
    testWidgets('shows the request count on the Requests tab', (tester) async {
      when(() => friendRequestBloc.state)
          .thenReturn(FriendRequestLoaded([request]));

      await tester.pumpWidget(buildSubject());

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows no count when there are no requests', (tester) async {
      when(() => friendRequestBloc.state)
          .thenReturn(const FriendRequestLoaded([]));

      await tester.pumpWidget(buildSubject());

      expect(find.text('0'), findsNothing);
    });

    testWidgets(
        'count clears when the bloc emits an empty list, with no remount '
        '— the original bug', (tester) async {
      whenListen(
        friendRequestBloc,
        Stream<FriendRequestState>.fromIterable([
          const FriendRequestLoaded([]),
        ]),
        initialState: FriendRequestLoaded([request]),
      );

      await tester.pumpWidget(buildSubject());
      expect(find.text('1'), findsOneWidget);

      await tester.pump();
      expect(find.text('1'), findsNothing);
    });
  });
}
