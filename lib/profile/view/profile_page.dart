import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/home_page.dart';
import 'package:magic_yeti/profile/bloc/profile_bloc.dart';

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
        userProfile: user,
      ),
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
              const SnackBar(content: Text('Profile Updated Successfully')),
            );
        }
        if (state.status == ProfileStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Failed to update profile'),
                backgroundColor: Colors.red,
              ),
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
                        previous.status != current.status,
                    builder: (context, state) {
                      if (state.status == ProfileStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Form(
                        child: Column(
                          children: [
                            if (state.userProfile.photo != null &&
                                state.userProfile.photo!.isNotEmpty)
                              Center(
                                child: CircleAvatar(
                                  radius: 75,
                                  backgroundImage:
                                      NetworkImage(state.userProfile.photo!),
                                ),
                              ),
                            if (state.userProfile.photo == null ||
                                state.userProfile.photo!.isEmpty)
                              Center(
                                child: CircleAvatar(
                                  radius: 75,
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  child: Text(
                                    (state.userProfile.name ?? '').isNotEmpty
                                        ? state.userProfile.name![0]
                                            .toUpperCase()
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
                              label: 'Username',
                              initialValue: state.userProfile.email ?? '',
                              onChanged: (value) => context
                                  .read<ProfileBloc>()
                                  .add(ProfileUsernameChanged(value)),
                            ),
                            _ProfileField(
                              label: 'Name',
                              initialValue: state.userProfile.name ?? '',
                              onChanged: (value) => context
                                  .read<ProfileBloc>()
                                  .add(ProfileFirstNameChanged(value)),
                            ),
                            // _ProfileField(
                            //   label: 'Last Name',
                            //   initialValue: state.userProfile.name ?? '',
                            //   onChanged: (value) => context
                            //       .read<ProfileBloc>()
                            //       .add(ProfileLastNameChanged(value)),
                            // ),
                            _ProfileField(
                              label: 'Email',
                              initialValue: state.userProfile.email ?? '',
                              onChanged: (value) => context
                                  .read<ProfileBloc>()
                                  .add(ProfileEmailChanged(value)),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                //   _EditProfileButton(),
                                //const SizedBox(width: 16),
                                _SignOutButton(),
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
          child: Text(state.isEditing ? 'Save Profile' : 'Edit Profile'),
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

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final String initialValue;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) => previous.isEditing != current.isEditing,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        ),
                        onChanged: onChanged,
                      )
                    : Text(initialValue.isEmpty ? 'Not set' : initialValue),
              ),
            ],
          ),
        );
      },
    );
  }
}
