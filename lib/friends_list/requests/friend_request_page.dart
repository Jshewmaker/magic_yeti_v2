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
          return ListView.builder(
            itemCount: state.requests.length,
            itemBuilder: (context, index) {
              final request = state.requests[index];
              return ListTile(
                title: Text(request.senderName),
                subtitle: Text('Request from: ${request.senderName}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        final userId = context.read<AppBloc>().state.user.id;
                        context
                            .read<FriendRequestBloc>()
                            .add(AcceptFriendRequest(request, userId));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        context
                            .read<FriendRequestBloc>()
                            .add(DeclineFriendRequest(request));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        } else if (state is FriendRequestError) {
          return Center(
              child: Text('Failed to load requests: ${state.message}'));
        }
        return Container();
      },
    );
  }
}
