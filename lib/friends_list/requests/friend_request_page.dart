import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';
import 'package:magic_yeti/friends_list/widgets/friend_card.dart';

class FriendRequestsPage extends StatelessWidget {
  const FriendRequestsPage({super.key});

  factory FriendRequestsPage.pageBuilder(_, __) {
    return const FriendRequestsPage(key: Key('friend_requests_page'));
  }

  static const routeName = 'friendRequests';
  static const routePath = '/friendRequests';

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppBloc>().state.user.id;
    return BlocProvider(
      create: (context) => FriendRequestBloc(
        repository: context.read<FirebaseDatabaseRepository>(),
      )..add(LoadFriendRequests(userId)),
      child: const FriendRequestView(),
    );
  }
}

class FriendRequestView extends StatelessWidget {
  const FriendRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendRequestBloc, FriendRequestState>(
      builder: (context, state) {
        if (state is FriendRequestLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FriendRequestLoaded) {
          if (state.requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending requests',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: state.requests.length,
            itemBuilder: (context, index) {
              final request = state.requests[index];
              return FriendCard(
                initial: request.senderName.isNotEmpty
                    ? request.senderName[0]
                    : '?',
                title: request.senderName,
                subtitle: 'Wants to be your friend',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: Icons.check,
                      color: AppColors.green,
                      onPressed: () {
                        final userId =
                            context.read<AppBloc>().state.user.id;
                        context.read<FriendRequestBloc>().add(
                              AcceptFriendRequest(request, userId),
                            );
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.close,
                      color: AppColors.red,
                      onPressed: () {
                        final userId =
                            context.read<AppBloc>().state.user.id;
                        context.read<FriendRequestBloc>().add(
                              DeclineFriendRequest(request, userId),
                            );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        } else if (state is FriendRequestError) {
          return Center(
            child: Text(
              'Failed to load requests: ${state.message}',
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
