import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 500,
              child: Column(
                children: [
                  if (user.imageUrl != null && user.imageUrl!.isNotEmpty)
                    Center(
                      child: CircleAvatar(
                        radius: 75,
                        backgroundImage: NetworkImage(user.imageUrl!),
                      ),
                    ),
                  const SizedBox(height: 50),
                  _ProfileField(
                      label: 'Username', value: user.username ?? 'Not set'),
                  _ProfileField(
                    label: 'First Name',
                    value: user.firstName ?? 'Not set',
                  ),
                  _ProfileField(
                    label: 'Last Name',
                    value: user.lastName ?? 'Not set',
                  ),
                  _ProfileField(label: 'Email', value: user.email ?? 'Not set'),
                  _ProfileField(label: 'Bio', value: user.bio ?? 'Not set'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Add edit profile functionality
                        },
                        child: const Text('Edit Profile'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<AppBloc>()
                              .add(const AppLogoutRequested());
                          context.pop();
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ],
              ),
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
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
