import 'dart:async';
import 'dart:typed_data';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:image_picker/image_picker.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/onboarding/onboarding.dart';

class OnboardingForm extends StatefulWidget {
  const OnboardingForm({super.key});

  @override
  State<OnboardingForm> createState() => _OnboardingFormState();
}

class _OnboardingFormState extends State<OnboardingForm> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (previous, current) =>
          previous.currentStep != current.currentStep ||
          previous.status != current.status,
      listener: (context, state) {
        // Animate page transitions
        if (_pageController.hasClients) {
          unawaited(_pageController.animateToPage(
            state.currentStep,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ));
        }
        // Handle submission result
        if (state.status.isSuccess) {
          context.read<AppBloc>().add(const AppOnboardingCompleted());
        } else if (state.status.isFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(context.l10n.onboardingSaveFailedMessage),
                backgroundColor: AppColors.red,
              ),
            );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // Progress indicator
            _StepIndicator(currentStep: state.currentStep),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _IdentityStep(),
                  _PinStep(),
                  _ProfilePictureStep(),
                  _BioStep(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index <= currentStep
                    ? AppColors.tertiary
                    : AppColors.neutral60,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Step 1: Identity (Username + Names)
// Uses StatefulWidget to own TextEditingControllers with proper lifecycle.
class _IdentityStep extends StatefulWidget {
  const _IdentityStep();

  @override
  State<_IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends State<_IdentityStep> {
  late final TextEditingController _usernameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    _usernameController = TextEditingController(text: state.username.value);
    _firstNameController = TextEditingController(text: state.firstName);
    _lastNameController = TextEditingController(text: state.lastName);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      header: 'Choose Your Identity',
      explanation: 'Your username is how other players will find you. '
          "It's used for friend requests and game history.",
      showBack: false,
      child: Column(
        children: [
          BlocBuilder<OnboardingBloc, OnboardingState>(
            buildWhen: (previous, current) =>
                previous.username != current.username,
            builder: (context, state) {
              return TextField(
                key: const Key('onboarding_username_input'),
                controller: _usernameController,
                onChanged: (value) => context
                    .read<OnboardingBloc>()
                    .add(OnboardingUsernameChanged(value)),
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Username *',
                  labelStyle: const TextStyle(color: AppColors.neutral60),
                  filled: true,
                  fillColor: AppColors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neutral60),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.tertiary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.red),
                  ),
                  errorText: state.username.displayError != null
                      ? 'Username is required'
                      : null,
                  errorStyle: const TextStyle(color: AppColors.red),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('onboarding_firstName_input'),
            controller: _firstNameController,
            onChanged: (value) => context
                .read<OnboardingBloc>()
                .add(OnboardingFirstNameChanged(value)),
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'First Name (Optional)',
              labelStyle: const TextStyle(color: AppColors.neutral60),
              filled: true,
              fillColor: AppColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neutral60),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.tertiary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('onboarding_lastName_input'),
            controller: _lastNameController,
            onChanged: (value) => context
                .read<OnboardingBloc>()
                .add(OnboardingLastNameChanged(value)),
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Last Name (Optional)',
              labelStyle: const TextStyle(color: AppColors.neutral60),
              filled: true,
              fillColor: AppColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neutral60),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.tertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Step 2: PIN Setup
class _PinStep extends StatelessWidget {
  const _PinStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (previous, current) =>
          previous.pin != current.pin ||
          previous.hasExistingPin != current.hasExistingPin,
      builder: (context, state) {
        final hasExistingPin = state.hasExistingPin;
        return _StepLayout(
          header: 'Set Your PIN',
          explanation: hasExistingPin
              ? 'Your PIN is already set. Enter a new 4-digit PIN '
                  'to change it, or tap Next to keep your current one.'
              : 'Your 4-digit PIN protects your profile when sharing '
                  'a device during games.',
          child: TextField(
            key: const Key('onboarding_pin_input'),
            onChanged: (value) => context
                .read<OnboardingBloc>()
                .add(OnboardingPinChanged(value)),
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              color: AppColors.white,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neutral60),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.tertiary),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.red),
              ),
              errorText: !hasExistingPin && state.pin.displayError != null
                  ? 'PIN must be exactly 4 digits'
                  : null,
              errorStyle: const TextStyle(color: AppColors.red),
            ),
          ),
        );
      },
    );
  }
}

// Step 3: Profile Picture
// Uses FutureBuilder to load image bytes for cross-platform preview.
class _ProfilePictureStep extends StatelessWidget {
  const _ProfilePictureStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (previous, current) =>
          previous.profileImagePath != current.profileImagePath ||
          previous.existingImageUrl != current.existingImageUrl ||
          previous.username != current.username,
      builder: (context, state) {
        return _StepLayout(
          header: 'Add a Profile Picture',
          explanation: 'Help your friends recognize you. This is optional — '
              'you can always add one later in your profile.',
          child: Column(
            children: [
              const SizedBox(height: 24),
              _ProfileImagePreview(
                imagePath: state.profileImagePath,
                existingImageUrl: state.existingImageUrl,
                initial: state.username.value.isNotEmpty
                    ? state.username.value[0].toUpperCase()
                    : '?',
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 80,
                  );
                  if (image != null && context.mounted) {
                    context.read<OnboardingBloc>().add(
                          OnboardingProfileImagePicked(image.path),
                        );
                  }
                },
                icon: const Icon(
                  Icons.photo_library,
                  color: AppColors.tertiary,
                ),
                label: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: AppColors.tertiary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.tertiary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Clear any selected image and advance
                  context.read<OnboardingBloc>().add(
                        const OnboardingProfileImagePicked(''),
                      );
                  context.read<OnboardingBloc>().add(
                        const OnboardingStepNext(),
                      );
                },
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: AppColors.neutral60),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileImagePreview extends StatelessWidget {
  const _ProfileImagePreview({
    required this.initial,
    this.imagePath,
    this.existingImageUrl,
  });

  final String? imagePath;
  final String? existingImageUrl;
  final String initial;

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      // Use XFile.readAsBytes for cross-platform image loading
      return FutureBuilder<Uint8List>(
        future: XFile(imagePath!).readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              radius: 64,
              backgroundColor: AppColors.tertiary,
              backgroundImage: MemoryImage(snapshot.data!),
            );
          }
          return _placeholder();
        },
      );
    }
    if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 64,
        backgroundColor: AppColors.tertiary,
        backgroundImage: NetworkImage(existingImageUrl!),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return CircleAvatar(
      radius: 64,
      backgroundColor: AppColors.tertiary,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
    );
  }
}

// Step 4: Bio
class _BioStep extends StatelessWidget {
  const _BioStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return _StepLayout(
          header: 'Tell Us About Yourself',
          explanation: 'Share a bit about your play style or favorite formats. '
              'Other players can see this on your profile.',
          buttonText: 'Complete',
          isSubmit: true,
          isLoading: state.status.isInProgress,
          child: _OptionalTextField(
            key: const Key('onboarding_bio_input'),
            label: 'Bio (Optional)',
            initialValue: context.read<OnboardingBloc>().state.bio,
            maxLines: 3,
            onChanged: (value) => context
                .read<OnboardingBloc>()
                .add(OnboardingBioChanged(value)),
          ),
        );
      },
    );
  }
}

// Shared step layout with header, explanation, content, and nav buttons
class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.header,
    required this.explanation,
    required this.child,
    this.showBack = true,
    this.buttonText = 'Next',
    this.isSubmit = false,
    this.isLoading = false,
  });

  final String header;
  final String explanation;
  final Widget child;
  final bool showBack;
  final String buttonText;
  final bool isSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            header,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral60,
            ),
          ),
          const SizedBox(height: 32),
          child,
          const Spacer(),
          Row(
            children: [
              if (showBack)
                Expanded(
                  child: TextButton(
                    onPressed: () => context
                        .read<OnboardingBloc>()
                        .add(const OnboardingStepBack()),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: AppColors.neutral60),
                    ),
                  ),
                ),
              if (showBack) const SizedBox(width: 16),
              Expanded(
                flex: showBack ? 2 : 1,
                child: BlocBuilder<OnboardingBloc, OnboardingState>(
                  buildWhen: (previous, current) =>
                      previous.isStepValid != current.isStepValid ||
                      previous.status != current.status,
                  builder: (context, state) {
                    return FilledButton(
                      onPressed: state.isStepValid && !isLoading
                          ? () {
                              if (isSubmit) {
                                final userId = context
                                    .read<AppBloc>()
                                    .state
                                    .user
                                    .id;
                                context.read<OnboardingBloc>().add(
                                      OnboardingSubmitted(userId),
                                    );
                              } else {
                                context.read<OnboardingBloc>().add(
                                      const OnboardingStepNext(),
                                    );
                              }
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.tertiary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(buttonText),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Reusable optional text field with dark theme
class _OptionalTextField extends StatelessWidget {
  const _OptionalTextField({
    required this.label,
    required this.onChanged,
    super.key,
    this.initialValue = '',
    this.maxLines = 1,
  });

  final String label;
  final String initialValue;
  final int maxLines;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.neutral60),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutral60),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.tertiary),
        ),
      ),
    );
  }
}
