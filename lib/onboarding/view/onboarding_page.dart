import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/onboarding/onboarding.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  factory OnboardingPage.pageBuilder(_, __) {
    return const OnboardingPage(
      key: Key('onboarding_page'),
    );
  }
  static const routeName = '/onboarding';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocProvider(
          create: (context) => OnboardingBloc(
            firebaseDatabaseRepository:
                context.read<FirebaseDatabaseRepository>(),
            userProfile: context.read<UserProfileModel>(),
          ),
          child: const OnboardingForm(),
        ),
      ),
    );
  }
}
