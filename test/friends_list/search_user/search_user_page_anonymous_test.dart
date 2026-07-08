import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/search_user/search_user_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:user_repository/user_repository.dart';

import '../../helpers/pump_app.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockFirebaseDatabaseRepository extends Mock
    implements FirebaseDatabaseRepository {}

void main() {
  group('SearchUserPage anonymous placeholder', () {
    late MockAppBloc appBloc;
    late MockFirebaseDatabaseRepository databaseRepository;

    setUp(() {
      appBloc = MockAppBloc();
      databaseRepository = MockFirebaseDatabaseRepository();
    });

    Future<void> pumpSearchUserPage(WidgetTester tester) async {
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
          ],
          child: RepositoryProvider<FirebaseDatabaseRepository>.value(
            value: databaseRepository,
            child: const SearchUserPage(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
        'shows signInToSearchFriends copy instead of the search field '
        'when anonymous', (tester) async {
      when(() => appBloc.state).thenReturn(
        const AppState.anonymous(User(id: 'anon1')),
      );

      await pumpSearchUserPage(tester);

      expect(find.text('Sign in to add friends.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets(
        'shows the search field (not the anonymous placeholder) '
        'when authenticated', (tester) async {
      when(() => appBloc.state).thenReturn(
        const AppState.authenticated(User(id: 'alice')),
      );

      await pumpSearchUserPage(tester);

      expect(find.text('Sign in to add friends.'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
