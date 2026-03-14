import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/onboarding/onboarding.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  factory OnboardingPage.pageBuilder(_, __) {
    return const OnboardingPage(
      key: Key('onboarding_page'),
    );
  }

  static const routeName = '/onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final Future<UserProfileModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = context
        .read<FirebaseDatabaseRepository>()
        .getUserProfileOnce(
          context.read<AppBloc>().state.user.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<UserProfileModel?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return BlocProvider(
              create: (context) => OnboardingBloc(
                firebaseDatabaseRepository:
                    context.read<FirebaseDatabaseRepository>(),
                existingProfile: snapshot.data,
              ),
              child: const OnboardingForm(),
            );
          },
        ),
      ),
    );
  }
}
