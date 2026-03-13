import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';

/// This file implements the UI and logic for managing friend requests.
/// It allows users to send and accept friend requests within the app.
///
/// Key features:
/// - Search for users to send friend requests
/// - View incoming friend requests
/// - Accept or decline friend requests
///
/// @dependencies
/// - Flutter Bloc: For state management
/// - Firebase Firestore: For storing and retrieving friend requests
///
/// @notes
/// - Handles network errors and provides user feedback
/// - Ensures real-time updates with Firestore
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
    return Scaffold(
      body: BlocProvider(
        create: (context) => FriendRequestBloc(
          repository: context.read<FirebaseDatabaseRepository>(),
        )..add(LoadFriendRequests(userId)),
        child: const FriendRequestView(),
      ),
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
            itemCount: state.requests.length,
            itemBuilder: (context, index) {
              final request = state.requests[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.tertiary,
                  child: Text(
                    request.senderName.isNotEmpty
                        ? request.senderName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.white,
                    ),
                  ),
                ),
                title: Text(
                  request.senderName,
                  style: const TextStyle(
                    color: AppColors.white,
                  ),
                ),
                subtitle: const Text(
                  'Wants to be your friend',
                  style: TextStyle(
                    color: AppColors.neutral60,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle,
                        color: AppColors.green,
                      ),
                      onPressed: () {
                        final userId =
                            context.read<AppBloc>().state.user.id;
                        context.read<FriendRequestBloc>().add(
                              AcceptFriendRequest(request, userId),
                            );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel,
                        color: AppColors.red,
                      ),
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
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
