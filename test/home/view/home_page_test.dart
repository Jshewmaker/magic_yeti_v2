import 'package:app_ui/app_ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';
import 'package:magic_yeti/home/home.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scryfall_repository/scryfall_repository.dart';
import 'package:user_repository/user_repository.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockMatchHistoryBloc
    extends MockBloc<MatchHistoryEvent, MatchHistoryState>
    implements MatchHistoryBloc {}

class _MockFriendRequestBloc
    extends MockBloc<FriendRequestEvent, FriendRequestState>
    implements FriendRequestBloc {}

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

class _MockScryfallRepository extends Mock implements ScryfallRepository {}

void main() {
  late AppBloc appBloc;
  late MatchHistoryBloc matchHistoryBloc;
  late FriendRequestBloc friendRequestBloc;
  late FirebaseDatabaseRepository databaseRepository;
  late ScryfallRepository scryfallRepository;

  const authenticatedUser = User(id: 'user-1');

  final pendingRequest = FriendRequestModel(
    id: 'bob_user-1',
    senderId: 'bob',
    senderName: 'Bob',
    receiverId: 'user-1',
    status: 'pending',
    timestamp: DateTime(2024),
  );

  setUp(() {
    appBloc = _MockAppBloc();
    matchHistoryBloc = _MockMatchHistoryBloc();
    friendRequestBloc = _MockFriendRequestBloc();
    databaseRepository = _MockFirebaseDatabaseRepository();
    scryfallRepository = _MockScryfallRepository();

    when(() => databaseRepository.getUserProfileOnce(any()))
        .thenAnswer((_) async => null);

    // HomePage's descendants read these three blocs' `.state` synchronously
    // while building — HomeSidePanel and MatchHistoryPanel watch AppBloc /
    // MatchHistoryBloc regardless of which layout or scenario a test cares
    // about, and (once home_page.dart wires it in Step 4) both layouts read
    // FriendRequestBloc too. Give every test a safe, already-proven-working
    // default (mirrors the tablet/authenticated test below) so tests that
    // only care about one bloc — like the "friend request dot" group, which
    // only wants to vary FriendRequestBloc — don't have to also stub the
    // other two. Mocktail matches the most-recently-registered stub, so a
    // test that calls whenListen/when itself simply overrides this default.
    when(() => appBloc.state)
        .thenReturn(const AppState.authenticated(authenticatedUser));
    when(() => matchHistoryBloc.state).thenReturn(
      const MatchHistoryState(
        status: MatchHistoryStatus.loadingHistorySuccess,
        userId: 'user-1',
      ),
    );
    when(() => friendRequestBloc.state).thenReturn(FriendRequestLoading());
  });

  void setViewSize(WidgetTester tester, {required bool isPhone}) {
    // The Ahem test font renders much wider than production fonts, so give
    // the phone surface extra width while staying under the tablet
    // breakpoint (shortestSide < 600).
    tester.view.physicalSize =
        isPhone ? const Size(590, 1100) : const Size(1366, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget buildSubject({required bool isPhone}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DeviceInfoProvider(
        isPhone: isPhone,
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: databaseRepository),
            RepositoryProvider.value(value: scryfallRepository),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: appBloc),
              BlocProvider.value(value: matchHistoryBloc),
              BlocProvider.value(value: friendRequestBloc),
            ],
            child: const HomePage(),
          ),
        ),
      ),
    );
  }

  group('HomePage', () {
    testWidgets('phone layout shows tabs with the game mode panel first',
        (tester) async {
      whenListen(
        appBloc,
        const Stream<AppState>.empty(),
        initialState: AppState.anonymous(
          authenticatedUser.copyWith(isAnonymous: true),
        ),
      );
      whenListen(
        matchHistoryBloc,
        const Stream<MatchHistoryState>.empty(),
        initialState: const MatchHistoryState(),
      );

      setViewSize(tester, isPhone: true);
      await tester.pumpWidget(buildSubject(isPhone: true));
      await tester.pump();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(HomeSidePanel), findsOneWidget);
      expect(find.byType(GameModeButtons), findsOneWidget);
      expect(find.byType(AddMatchFab), findsOneWidget);
      // Anonymous users see login/sign-up instead of stats.
      expect(find.byType(StatsOverviewWidget), findsNothing);
    });

    testWidgets('tablet layout shows the side panel and match history '
        'side by side', (tester) async {
      whenListen(
        appBloc,
        const Stream<AppState>.empty(),
        initialState: const AppState.authenticated(authenticatedUser),
      );
      whenListen(
        matchHistoryBloc,
        const Stream<MatchHistoryState>.empty(),
        initialState: const MatchHistoryState(
          status: MatchHistoryStatus.loadingHistorySuccess,
          userId: 'user-1',
        ),
      );

      setViewSize(tester, isPhone: false);
      await tester.pumpWidget(buildSubject(isPhone: false));
      await tester.pump();

      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(HomeSidePanel), findsOneWidget);
      expect(find.byType(MatchHistoryPanel), findsOneWidget);
      // Signed-in users get the stats overview, compiled from the already
      // loaded (empty) match history.
      expect(find.byType(StatsOverviewWidget), findsOneWidget);
      await tester.pump();
      expect(find.byType(StatsGrid), findsOneWidget);
    });

    testWidgets('shows the match history skeleton while games load',
        (tester) async {
      whenListen(
        appBloc,
        const Stream<AppState>.empty(),
        initialState: const AppState.authenticated(authenticatedUser),
      );
      whenListen(
        matchHistoryBloc,
        const Stream<MatchHistoryState>.empty(),
        initialState: const MatchHistoryState(
          status: MatchHistoryStatus.loadingHistory,
          userId: 'user-1',
        ),
      );

      setViewSize(tester, isPhone: false);
      await tester.pumpWidget(buildSubject(isPhone: false));
      await tester.pump();

      expect(find.byType(MatchHistorySkeleton), findsOneWidget);
      // Stats stay skeletal until the history arrives.
      expect(find.byType(StatsOverviewSkeleton), findsOneWidget);
    });
  });

  group('friend request dot', () {
    for (final isPhone in [true, false]) {
      final layout = isPhone ? 'phone' : 'tablet';

      testWidgets('$layout: shows a dot when a request is pending',
          (tester) async {
        setViewSize(tester, isPhone: isPhone);
        when(() => friendRequestBloc.state)
            .thenReturn(FriendRequestLoaded([pendingRequest]));

        await tester.pumpWidget(buildSubject(isPhone: isPhone));
        await tester.pumpAndSettle();

        expect(find.byType(NotificationDot), findsOneWidget);
      });

      testWidgets('$layout: shows no dot when there are no requests',
          (tester) async {
        setViewSize(tester, isPhone: isPhone);
        when(() => friendRequestBloc.state)
            .thenReturn(const FriendRequestLoaded([]));

        await tester.pumpWidget(buildSubject(isPhone: isPhone));
        await tester.pumpAndSettle();

        expect(find.byType(NotificationDot), findsNothing);
      });

      testWidgets('$layout: shows no dot while the stream is erroring',
          (tester) async {
        setViewSize(tester, isPhone: isPhone);
        when(() => friendRequestBloc.state)
            .thenReturn(const FriendRequestError('boom'));

        await tester.pumpWidget(buildSubject(isPhone: isPhone));
        await tester.pumpAndSettle();

        expect(find.byType(NotificationDot), findsNothing);
      });
    }
  });
}
