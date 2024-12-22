// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/login/login.dart';
import 'package:user_repository/user_repository.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  factory LoginPage.pageBuilder(_, __) {
    return const LoginPage(
      key: Key('login_page'),
    );
  }

  static const routeName = '/login';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(context.read<UserRepository>())
        ..add(const GoogleSignInWebInitialized()),
      child: const LoginView(),
    );
  }
}
