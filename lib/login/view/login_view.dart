// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/login/login.dart';
import 'package:magic_yeti/reset_password/reset_password.dart';
import 'package:magic_yeti/sign_up/sign_up.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state.status.isSuccess) {
            context.goNamed(HomePage.routeName);
          }
          if (state.status.isFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.authenticationFailure)),
              );
          }
        },
        child: const SafeArea(
          minimum: EdgeInsets.all(AppSpacing.xlg),
          child: ScrollableColumn(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LoginContent(),
              _LoginActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xlg),
        Text(l10n.loginWelcomeText, style: theme.textTheme.displayLarge),
        const SizedBox(height: AppSpacing.xxlg),
        const EmailInput(),
        const SizedBox(height: AppSpacing.xs),
        const PasswordInput(),
        const SizedBox(height: AppSpacing.xs),
        const ResetPasswordButton(),
      ],
    );
  }
}

class _LoginActions extends StatelessWidget {
  const _LoginActions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoginButton(),
        const SizedBox(height: AppSpacing.xlg),
        const GoogleLoginButton(),
        if (theme.platform == TargetPlatform.iOS) ...[
          const SizedBox(height: AppSpacing.xlg),
          const AppleLoginButton(),
        ],
        const SizedBox(height: AppSpacing.xxlg),
        const SignUpButton(),
      ],
    );
  }
}

class EmailInput extends StatelessWidget {
  @visibleForTesting
  const EmailInput({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = context.select((LoginBloc bloc) => bloc.state.email);
    return TextField(
      onChanged: (email) {
        context.read<LoginBloc>().add(LoginEmailChanged(email));
      },
      decoration: InputDecoration(
        helperText: '',
        labelText: l10n.emailInputLabelText,
        errorText:
            email.displayError != null ? l10n.invalidEmailInputErrorText : null,
      ),
      autofillHints: const [AutofillHints.email],
      keyboardType: TextInputType.emailAddress,
      keyboardAppearance: Theme.of(context).brightness,
      autocorrect: false,
    );
  }
}

class PasswordInput extends StatelessWidget {
  @visibleForTesting
  const PasswordInput({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final password = context.select((LoginBloc bloc) => bloc.state.password);
    return TextField(
      onChanged: (password) {
        context.read<LoginBloc>().add(LoginPasswordChanged(password));
      },
      obscureText: true,
      autofillHints: const [AutofillHints.password],
      keyboardType: TextInputType.visiblePassword,
      keyboardAppearance: Theme.of(context).brightness,
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

class LoginButton extends StatelessWidget {
  @visibleForTesting
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<LoginBloc>().state;
    return ElevatedButton(
      onPressed: state.valid
          ? () =>
              context.read<LoginBloc>().add(const LoginCredentialsSubmitted())
          : null,
      child: state.status.isInProgress
          ? const CircularProgressIndicator()
          : Text(l10n.loginButtonText),
    );
  }
}

class AppleLoginButton extends StatelessWidget {
  @visibleForTesting
  const AppleLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ElevatedButton.icon(
      label: Text(l10n.signInWithAppleButtonText),
      icon: const Icon(FontAwesomeIcons.apple, color: AppColors.white),
      onPressed: () =>
          context.read<LoginBloc>().add(const LoginAppleSubmitted()),
    );
  }
}

class GoogleLoginButton extends StatelessWidget {
  @visibleForTesting
  const GoogleLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ElevatedButton(
      onPressed: () =>
          context.read<LoginBloc>().add(const LoginGoogleSubmitted()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FontAwesomeIcons.google, color: AppColors.white),
          const SizedBox(width: AppSpacing.xlg),
          Text(l10n.signInWithGoogleButtonText),
        ],
      ),
    );
  }
}

class SignUpButton extends StatelessWidget {
  @visibleForTesting
  const SignUpButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextButton(
      onPressed: () => context.goNamed(SignUpPage.routeName),
      child: Text(l10n.createAccountButtonText),
    );
  }
}

class ResetPasswordButton extends StatelessWidget {
  @visibleForTesting
  const ResetPasswordButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextButton(
      onPressed: () => context.goNamed(ResetPasswordPage.routeName),
      child: Text(l10n.forgotPasswordText),
    );
  }
}
