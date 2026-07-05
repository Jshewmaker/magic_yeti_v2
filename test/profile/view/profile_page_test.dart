import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/profile/bloc/profile_bloc.dart';
import 'package:magic_yeti/profile/view/profile_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:user_repository/user_repository.dart';

import '../../helpers/pump_app.dart';

class MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

void main() {
  group('ProfileView', () {
    late MockAppBloc appBloc;
    late MockProfileBloc profileBloc;

    const authUser = User(id: 'u1', email: 'josh@example.com', name: 'Josh');

    const loadedProfile = UserProfileModel(
      id: 'u1',
      email: 'josh@example.com',
      username: 'joshy',
      firstName: 'Josh',
      lastName: 'Shew',
      bio: 'Commander enjoyer',
      friendCode: 'YETI-A3F9',
      hasPin: true,
      onboardingComplete: true,
    );

    setUp(() {
      appBloc = MockAppBloc();
      profileBloc = MockProfileBloc();
      when(() => appBloc.state)
          .thenReturn(const AppState.authenticated(authUser));
    });

    Future<void> pumpProfile(WidgetTester tester) async {
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<ProfileBloc>.value(value: profileBloc),
          ],
          child: const ProfileView(),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows a loading indicator while the profile loads',
        (tester) async {
      when(() => profileBloc.state).thenReturn(
        const ProfileState(user: authUser, status: ProfileStatus.loading),
      );

      await pumpProfile(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'renders username/name/bio from the loaded UserProfileModel, '
        'not the auth User', (tester) async {
      when(() => profileBloc.state).thenReturn(
        const ProfileState(
          user: authUser,
          status: ProfileStatus.loaded,
          profile: loadedProfile,
        ),
      );

      await pumpProfile(tester);

      expect(find.text('joshy'), findsOneWidget);
      expect(find.textContaining('Josh'), findsWidgets);
      expect(find.text('Shew'), findsOneWidget);
      expect(find.text('Commander enjoyer'), findsOneWidget);
    });

    testWidgets('renders the friend code row with the loaded friend code',
        (tester) async {
      when(() => profileBloc.state).thenReturn(
        const ProfileState(
          user: authUser,
          status: ProfileStatus.loaded,
          profile: loadedProfile,
        ),
      );

      await pumpProfile(tester);

      expect(find.text('YETI-A3F9'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('renders the PIN change section', (tester) async {
      when(() => profileBloc.state).thenReturn(
        const ProfileState(
          user: authUser,
          status: ProfileStatus.loaded,
          profile: loadedProfile,
        ),
      );

      await pumpProfile(tester);

      expect(find.text('Change PIN'), findsOneWidget);
      expect(find.text('New PIN'), findsOneWidget);
    });

    testWidgets('entering a pin dispatches ProfilePinChanged', (tester) async {
      when(() => profileBloc.state).thenReturn(
        const ProfileState(
          user: authUser,
          status: ProfileStatus.loaded,
          profile: loadedProfile,
        ),
      );

      await pumpProfile(tester);

      await tester.enterText(
        find.byKey(const Key('profile_pin_field')),
        '1234',
      );

      verify(() => profileBloc.add(const ProfilePinChanged('1234'))).called(1);
    });

    testWidgets('tapping save with a valid pin dispatches ProfilePinSubmitted',
        (tester) async {
      when(() => profileBloc.state).thenReturn(
        const ProfileState(
          user: authUser,
          status: ProfileStatus.loaded,
          profile: loadedProfile,
          pin: Pin.dirty('1234'),
        ),
      );

      await pumpProfile(tester);

      await tester.ensureVisible(
        find.byKey(const Key('profile_pin_submit_button')),
      );
      await tester.tap(find.byKey(const Key('profile_pin_submit_button')));
      await tester.pump();

      verify(() => profileBloc.add(const ProfilePinSubmitted())).called(1);
    });

    testWidgets('shows the pin changed snackbar on pinSaved status',
        (tester) async {
      whenListen(
        profileBloc,
        Stream.fromIterable([
          const ProfileState(
            user: authUser,
            status: ProfileStatus.loaded,
            profile: loadedProfile,
          ),
          const ProfileState(
            user: authUser,
            status: ProfileStatus.pinSaved,
            profile: loadedProfile,
          ),
        ]),
        initialState: const ProfileState(
          user: authUser,
          status: ProfileStatus.loaded,
          profile: loadedProfile,
        ),
      );

      await pumpProfile(tester);
      await tester.pump();

      expect(find.text('PIN updated!'), findsOneWidget);
    });

    testWidgets('shows the profile saved snackbar on success status',
        (tester) async {
      whenListen(
        profileBloc,
        Stream.fromIterable([
          const ProfileState(
            user: authUser,
            status: ProfileStatus.loaded,
            profile: loadedProfile,
          ),
          const ProfileState(
            user: authUser,
            status: ProfileStatus.success,
            profile: loadedProfile,
          ),
        ]),
        initialState: const ProfileState(
          user: authUser,
          status: ProfileStatus.loaded,
          profile: loadedProfile,
        ),
      );

      await pumpProfile(tester);
      await tester.pump();

      expect(find.text('Profile saved'), findsOneWidget);
    });

    testWidgets('shows the profile save failed snackbar on failure status',
        (tester) async {
      whenListen(
        profileBloc,
        Stream.fromIterable([
          const ProfileState(
            user: authUser,
            status: ProfileStatus.loaded,
            profile: loadedProfile,
          ),
          const ProfileState(
            user: authUser,
            status: ProfileStatus.failure,
            profile: loadedProfile,
          ),
        ]),
        initialState: const ProfileState(
          user: authUser,
          status: ProfileStatus.loaded,
          profile: loadedProfile,
        ),
      );

      await pumpProfile(tester);
      await tester.pump();

      expect(find.text("Couldn't save your profile. Try again."),
          findsOneWidget);
    });

    testWidgets('email field is read-only (no ProfileEmailChanged event)',
        (tester) async {
      when(() => profileBloc.state).thenReturn(
        const ProfileState(
          user: authUser,
          status: ProfileStatus.loaded,
          profile: loadedProfile,
          isEditing: true,
        ),
      );

      await pumpProfile(tester);

      expect(find.text('josh@example.com'), findsOneWidget);
      // No editable text field is bound to email; only the username,
      // first/last name, and bio fields are editable text fields.
      expect(find.byType(TextFormField), findsNWidgets(4));
    });
  });
}
