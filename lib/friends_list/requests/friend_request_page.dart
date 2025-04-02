import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
      ),
      body: BlocProvider(
        create: (context) => FriendRequestBloc(
          repository: context.read<FirebaseDatabaseRepository>(),
        ),
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
                subtitle: Text('Request from: ${request.requestId}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        context
                            .read<FriendRequestBloc>()
                            .add(AcceptFriendRequest(request));
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
