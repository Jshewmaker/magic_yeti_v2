import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/onboarding/onboarding.dart';

class OnboardingForm extends StatelessWidget {
  const OnboardingForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.status.isSuccess) {
          context.go(HomePage.routeName);
        } else if (state.status.isFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Failed to update profile. Please try again.'),
              ),
            );
        }
      },
      child: const ScrollableColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WelcomeText(),
          SizedBox(height: AppSpacing.lg),
          _UsernameInput(),
          SizedBox(height: AppSpacing.xs),
          _FirstNameInput(),
          SizedBox(height: AppSpacing.xs),
          _LastNameInput(),
          SizedBox(height: AppSpacing.xs),
          _BioInput(),
          SizedBox(height: AppSpacing.lg),
          _SubmitButton(),
        ],
      ),
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Let\'s set up your profile.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _UsernameInput extends StatelessWidget {
  const _UsernameInput();

  @override
  Widget build(BuildContext context) {
    final username =
        context.select((OnboardingBloc bloc) => bloc.state.username);
    return TextField(
      key: const Key('onboardingForm_usernameInput_textField'),
      onChanged: (username) {
        context.read<OnboardingBloc>().add(OnboardingUsernameChanged(username));
      },
      decoration: InputDecoration(
        labelText: 'Username',
        helperText: '',
        errorText: username.displayError != null ? 'Invalid username' : null,
      ),
    );
  }
}

class _FirstNameInput extends StatelessWidget {
  const _FirstNameInput();

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('onboardingForm_firstNameInput_textField'),
      onChanged: (firstName) {
        context
            .read<OnboardingBloc>()
            .add(OnboardingFirstNameChanged(firstName));
      },
      decoration: const InputDecoration(
        labelText: 'First Name (Optional)',
        helperText: '',
      ),
    );
  }
}

class _LastNameInput extends StatelessWidget {
  const _LastNameInput();

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('onboardingForm_lastNameInput_textField'),
      onChanged: (lastName) {
        context.read<OnboardingBloc>().add(OnboardingLastNameChanged(lastName));
      },
      decoration: const InputDecoration(
        labelText: 'Last Name (Optional)',
        helperText: '',
      ),
    );
  }
}

class _BioInput extends StatelessWidget {
  const _BioInput();

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('onboardingForm_bioInput_textField'),
      onChanged: (bio) {
        context.read<OnboardingBloc>().add(OnboardingBioChanged(bio));
      },
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Bio (Optional)',
        helperText: 'Tell us about yourself and your gaming interests',
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingBloc>().state;
    return ElevatedButton(
      key: const Key('onboardingForm_submit_elevatedButton'),
      onPressed: state.isValid
          ? () {
              context.read<OnboardingBloc>().add(const OnboardingSubmitted());
            }
          : null,
      child: state.status.isInProgress
          ? const CircularProgressIndicator()
          : const Text('Complete Profile'),
    );
  }
}
