import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/login/login.dart';
import 'package:magic_yeti/sign_up/sign_up.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';

/// The account section of the home screen: the player's stats overview when
/// signed in, or login/sign-up actions otherwise.
class AccountWidget extends StatelessWidget {
  const AccountWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isSignedIn = !context.select(
      (AppBloc bloc) => bloc.state.user.isAnonymous,
    );

    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: isSignedIn
          ? const StatsOverviewWidget()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthButton(
                  label: l10n.loginButtonText,
                  onPressed: () => context.go(LoginPage.routeName),
                ),
                _AuthButton(
                  label: l10n.signUpAppBarTitle,
                  onPressed: () => context.go(SignUpPage.routeName),
                ),
              ],
            ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
