import 'package:app_ui/app_ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
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

class _MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

class _MockScryfallRepository extends Mock implements ScryfallRepository {}

void main() {
  late AppBloc appBloc;
  late MatchHistoryBloc matchHistoryBloc;
  late FirebaseDatabaseRepository databaseRepository;
  late ScryfallRepository scryfallRepository;

  const authenticatedUser = User(id: 'user-1');

  setUp(() {
    appBloc = _MockAppBloc();
    matchHistoryBloc = _MockMatchHistoryBloc();
    databaseRepository = _MockFirebaseDatabaseRepository();
    scryfallRepository = _MockScryfallRepository();

    when(() => databaseRepository.getUserProfileOnce(any()))
        .thenAnswer((_) async => null);
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
}
