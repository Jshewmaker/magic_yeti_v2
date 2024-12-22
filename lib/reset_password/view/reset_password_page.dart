// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/reset_password/reset_password.dart';
import 'package:user_repository/user_repository.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  factory ResetPasswordPage.pageBuilder(_, __) {
    return const ResetPasswordPage();
  }

  static String get routeName => 'reset-password';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResetPasswordBloc>(
      create: (_) => ResetPasswordBloc(context.read<UserRepository>()),
      child: const ResetPasswordView(),
    );
  }
}
