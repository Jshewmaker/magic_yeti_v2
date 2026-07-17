import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:go_router/go_router.dart';
import 'package:hold_to_confirm_button/hold_to_confirm_button.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/home.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/profile/bloc/profile_bloc.dart';
import 'package:user_repository/user_repository.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  factory ProfilePage.pageBuilder(_, __) {
    return const ProfilePage(key: Key('profile_page'));
  }

  static const routeName = 'profile';
  static const routePath = '/profile';

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppBloc bloc) => bloc.state.user);

    return BlocProvider(
      create: (context) => ProfileBloc(
        firebaseDatabaseRepository: context.read<FirebaseDatabaseRepository>(),
        userRepository: context.read<UserRepository>(),
        userProfile: user,
      )..add(ProfileLoadRequested(user.id)),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ProfileStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(context.l10n.profileSavedMessage)),
            );
        }
        if (state.status == ProfileStatus.usernameInvalid) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(context.l10n.usernameInvalidMessage),
                backgroundColor: Colors.red,
              ),
            );
        }
        if (state.status == ProfileStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(context.l10n.profileSaveFailedMessage),
                backgroundColor: Colors.red,
              ),
            );
        }
        if (state.status == ProfileStatus.pinSaved) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(context.l10n.pinChangedMessage)),
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.go(HomePage.routeName),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 500,
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    buildWhen: (previous, current) =>
                        previous.status != current.status ||
                        previous.isEditing != current.isEditing,
                    builder: (context, state) {
                      if (state.status == ProfileStatus.loading &&
                          state.profile == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final profile = state.profile;
                      if (profile == null) {
                        // Load hasn't produced a profile yet (e.g. failure
                        // before any successful load) — nothing to render.
                        return const SizedBox.shrink();
                      }

                      return Form(
                        child: Column(
                          children: [
                            if (profile.imageUrl != null &&
                                profile.imageUrl!.isNotEmpty)
                              Center(
                                child: CircleAvatar(
                                  radius: 75,
                                  backgroundImage:
                                      NetworkImage(profile.imageUrl!),
                                ),
                              ),
                            if (profile.imageUrl == null ||
                                profile.imageUrl!.isEmpty)
                              Center(
                                child: CircleAvatar(
                                  radius: 75,
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  child: Text(
                                    (profile.username ?? '').isNotEmpty
                                        ? profile.username![0].toUpperCase()
                                        : '',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 50),
                            _ProfileField(
                              label: context.l10n.usernameLabel,
                              initialValue: profile.username ?? '',
                              helperText: context.l10n.usernameHelperText,
                              errorTextBuilder: (context, state) =>
                                  switch (state.username?.displayError) {
                                UsernameValidationError.empty =>
                                  context.l10n.usernameRequiredError,
                                UsernameValidationError.tooShort =>
                                  context.l10n.usernameTooShortError,
                                UsernameValidationError.tooLong =>
                                  context.l10n.usernameTooLongError,
                                null => null,
                              },
                              onChanged: (value) => context
                                  .read<ProfileBloc>()
                                  .add(ProfileUsernameChanged(value)),
                            ),
                            _ProfileField(
                              label: context.l10n.bioLabel,
                              initialValue: profile.bio ?? '',
                              onChanged: (value) => context
                                  .read<ProfileBloc>()
                                  .add(ProfileBioChanged(value)),
                            ),
                            // Email is auth-managed and read-only here —
                            // there is no ProfileEmailChanged event/pathway
                            // anymore; edit via the auth provider instead.
                            _ReadOnlyProfileField(
                              label: context.l10n.emailLabel,
                              value: profile.email ?? '',
                            ),
                            const SizedBox(height: 20),
                            _FriendCodeSection(friendCode: profile.friendCode),
                            const SizedBox(height: 20),
                            const _ChangePinSection(),
                            const SizedBox(height: 20),
                            _EditProfileButton(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SignOutButton(),
                                const SizedBox(width: 16),
                                _DeleteProfileButton(),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) =>
          previous.isEditing != current.isEditing ||
          previous.status != current.status,
      builder: (context, state) {
        return ElevatedButton(
          onPressed: state.status == ProfileStatus.loading
              ? null
              : () {
                  if (state.isEditing) {
                    context.read<ProfileBloc>().add(const ProfileSubmitted());
                  } else {
                    context
                        .read<ProfileBloc>()
                        .add(const ProfileEditingToggled());
                  }
                },
          child: Text(
            state.isEditing
                ? context.l10n.saveProfileButton
                : context.l10n.editProfileButton,
          ),
        );
      },
    );
  }
}

class _DeleteProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return ElevatedButton(
          onPressed: state.status == ProfileStatus.loading
              ? null
              : () {
                  _showDeleteConfirmationDialog(context);
                },
          child: const Text('Delete Profile'),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: context.read<AppBloc>(),
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Delete Profile'),
                content: const Text(
                  'Are you sure you want to delete your profile? All of your data will be lost forever and cannot be recovered.',
                ),
                actions: [
                  ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel')),
                  HoldToConfirmButton(
                    child: const Text('Delete Profile'),
                    onProgressCompleted: () {
                      // Server-side cleanup (friends/requests/blocks tied
                      // to this account) now runs via a Firestore trigger
                      // on account deletion (see Task 1), so there is no
                      // client-side fan-out cleanup to trigger here.
                      context
                          .read<AppBloc>()
                          .add(const AppUserAccountDeleted());
                      context.pop();
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AppBloc, AppState>(
      listener: (context, state) {
        if (state.status == AppStatus.anonymous) {
          context.go(HomePage.routeName);
        }
      },
      child: ElevatedButton(
        onPressed: () {
          context.read<AppBloc>().add(const AppLogoutRequested());
        },
        child: const Text('Sign Out'),
      ),
    );
  }
}

class _FriendCodeSection extends StatelessWidget {
  const _FriendCodeSection({required this.friendCode});

  final String? friendCode;

  @override
  Widget build(BuildContext context) {
    final code = friendCode;
    if (code == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.friendCodeLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    code,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.friendCodeHelperText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // share_plus is not a dependency of the root app (checked
            // pubspec.yaml/pubspec.lock) — keeping copy-only rather than
            // adding a new dependency for this. If share_plus is added
            // later, wire a share icon here via Share.share(code).
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: context.l10n.copyFriendCodeTooltip,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.friendCodeCopiedMessage),
                    ),
                  );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePinSection extends StatefulWidget {
  const _ChangePinSection();

  @override
  State<_ChangePinSection> createState() => _ChangePinSectionState();
}

class _ChangePinSectionState extends State<_ChangePinSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.changePinTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.changePinDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('profile_pin_field'),
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.newPinLabel,
                      counterText: '',
                    ),
                    onChanged: (value) => context
                        .read<ProfileBloc>()
                        .add(ProfilePinChanged(value)),
                  ),
                ),
                const SizedBox(width: 16),
                BlocBuilder<ProfileBloc, ProfileState>(
                  buildWhen: (previous, current) =>
                      previous.pin != current.pin ||
                      previous.status != current.status,
                  builder: (context, state) {
                    return ElevatedButton(
                      key: const Key('profile_pin_submit_button'),
                      onPressed: state.pin.isValid &&
                              state.status != ProfileStatus.loading
                          ? () => context
                              .read<ProfileBloc>()
                              .add(const ProfilePinSubmitted())
                          : null,
                      child: Text(context.l10n.saveButtonText),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.helperText,
    this.errorTextBuilder,
  });

  final String label;
  final String initialValue;
  final void Function(String) onChanged;
  final String? helperText;

  /// Builds live inline error copy from bloc state; null for fields
  /// without validation. The parent builder only rebuilds on
  /// status/isEditing changes, so the error must flow through this
  /// widget's own BlocBuilder.
  final String? Function(BuildContext context, ProfileState state)?
      errorTextBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) =>
          previous.isEditing != current.isEditing ||
          previous.username != current.username,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: state.isEditing
                        ? TextFormField(
                            initialValue: initialValue,
                            decoration: InputDecoration(
                              hintText: 'Enter $label',
                              errorText:
                                  errorTextBuilder?.call(context, state),
                            ),
                            onChanged: onChanged,
                          )
                        : Text(
                            initialValue.isEmpty
                                ? context.l10n.notSetLabel
                                : initialValue,
                          ),
                  ),
                ],
              ),
              if (helperText != null)
                Padding(
                  padding: const EdgeInsets.only(left: 116, top: 2),
                  child: Text(
                    helperText!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReadOnlyProfileField extends StatelessWidget {
  const _ReadOnlyProfileField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value.isEmpty ? context.l10n.notSetLabel : value),
          ),
        ],
      ),
    );
  }
}
