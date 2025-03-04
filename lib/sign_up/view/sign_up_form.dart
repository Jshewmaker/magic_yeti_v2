// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/login/login.dart';
import 'package:magic_yeti/onboarding/onboarding.dart';
import 'package:magic_yeti/sign_up/sign_up.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocListener<SignUpBloc, SignUpState>(
      listener: (context, state) {
        if (state.status.isSuccess) {
          context.go(HomePage.routeName);
        } else if (state.status.isFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(l10n.signUpFailure)),
            );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ScrollableColumn(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _EmailInput(),
            const SizedBox(height: AppSpacing.xs),
            const _PasswordInput(),
            const SizedBox(height: AppSpacing.xs),
            const _SignUpButton(),
            const SizedBox(height: AppSpacing.xlg),
            GoogleLoginButton(
              buttonText: l10n.signUpWithGoogleButtonText,
              onPressed: () =>
                  context.read<SignUpBloc>().add(const SignUpGoogleSubmitted()),
            ),
            if (theme.platform == TargetPlatform.iOS) ...[
              AppleLoginButton(
                buttonText: l10n.signUpWithAppleButtonText,
                onPressed: () => context
                    .read<SignUpBloc>()
                    .add(const SignUpAppleSubmitted()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmailInput extends StatelessWidget {
  const _EmailInput();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = context.select((SignUpBloc bloc) => bloc.state.email);
    return TextField(
      key: const Key('signUpForm_emailInput_textField'),
      onChanged: (email) {
        context.read<SignUpBloc>().add(SignUpEmailChanged(email));
      },
      decoration: InputDecoration(
        helperText: '',
        labelText: l10n.emailInputLabelText,
        errorText:
            email.displayError != null ? l10n.invalidEmailInputErrorText : null,
      ),
      autocorrect: false,
    );
  }
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final password = context.select((SignUpBloc bloc) => bloc.state.password);
    return TextField(
      key: const Key('signUpForm_passwordInput_textField'),
      onChanged: (password) {
        context.read<SignUpBloc>().add(SignUpPasswordChanged(password));
      },
      obscureText: true,
      decoration: InputDecoration(
        helperText: '',
        labelText: l10n.passwordInputLabelText,
        errorText: password.displayError != null
            ? l10n.invalidPasswordInputErrorText
            : null,
      ),
    );
  }
}

class _SignUpButton extends StatelessWidget {
  const _SignUpButton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SignUpBloc>().state;
    return ElevatedButton(
      key: const Key('signUpForm_continue_elevatedButton'),
      onPressed: state.valid
          ? () => context.read<SignUpBloc>().add(const SignUpSubmitted())
          : null,
      child: state.status.isInProgress
          ? const CircularProgressIndicator()
          : Text(l10n.signUpButtonText),
    );
  }
}
