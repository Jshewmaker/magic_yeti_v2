// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/sign_up/sign_up.dart';
import 'package:user_repository/user_repository.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  factory SignUpPage.pageBuilder(_, __) {
    return const SignUpPage();
  }

  static String get routeName => '/sign-up';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.signUpAppBarTitle,
          style: theme.textTheme.displayMedium,
        ),
        actions: [
          IconButton(
            onPressed: () => context.go(HomePage.routeName),
            icon: const Icon(Icons.arrow_back),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxxlg,
          horizontal: AppSpacing.xlg,
        ),
        child: BlocProvider<SignUpBloc>(
          create: (_) => SignUpBloc(context.read<UserRepository>()),
          child: const SignUpForm(),
        ),
      ),
    );
  }
}
