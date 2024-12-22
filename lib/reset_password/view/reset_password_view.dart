// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/reset_password/reset_password.dart';

class ResetPasswordView extends StatelessWidget {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.resetPasswordTitle,
          style: theme.textTheme.displayMedium,
        ),
      ),
      body: BlocListener<ResetPasswordBloc, ResetPasswordState>(
        listener: (context, state) {
          if (state.status.isSuccess || state.status.isFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.resetPasswordSubmitText)),
              );
            context.pop();
          }
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.xxxlg,
            horizontal: AppSpacing.xlg,
          ),
          child: ScrollableColumn(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmailInput(),
              SizedBox(height: AppSpacing.xs),
              SubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class EmailInput extends StatelessWidget {
  @visibleForTesting
  const EmailInput({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = context.select((ResetPasswordBloc bloc) => bloc.state.email);
    return TextField(
      onChanged: (email) {
        context.read<ResetPasswordBloc>().add(ResetPasswordEmailChanged(email));
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

class SubmitButton extends StatelessWidget {
  @visibleForTesting
  const SubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<ResetPasswordBloc>().state;
    return ElevatedButton(
      onPressed: state.valid
          ? () => context
              .read<ResetPasswordBloc>()
              .add(const ResetPasswordSubmitted())
          : null,
      child: state.status.isInProgress
          ? const CircularProgressIndicator()
          : Text(l10n.submitButtonText),
    );
  }
}
