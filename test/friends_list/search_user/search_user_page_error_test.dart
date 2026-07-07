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
  group('SearchUserPage error state', () {
    late MockAppBloc appBloc;
    late MockFirebaseDatabaseRepository databaseRepository;

    setUp(() {
      appBloc = MockAppBloc();
      databaseRepository = MockFirebaseDatabaseRepository();
      when(() => appBloc.state).thenReturn(
        const AppState.authenticated(User(id: 'alice')),
      );
    });

    testWidgets('renders localized copy, not the raw exception',
        (tester) async {
      when(() => databaseRepository.searchByUsername(any()))
          .thenThrow(Exception('boom'));

      await tester.pumpApp(
        MultiBlocProvider(
          providers: [BlocProvider<AppBloc>.value(value: appBloc)],
          child: RepositoryProvider<FirebaseDatabaseRepository>.value(
            value: databaseRepository,
            child: const SearchUserPage(),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'someone');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        find.text('Search failed. Check your connection and try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('boom'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });
  });
}
