import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list/bloc/friend_list_bloc.dart';

/// This file implements the UI for displaying and managing the user's friends list.
/// It allows users to view their friends and remove them if desired.
///
/// Key features:
/// - Display a list of current friends
/// - Remove friends with confirmation
///
/// @dependencies
/// - Flutter Bloc: For state management
/// - Firebase Database Repository: To interact with Firestore
///
/// @notes
/// - Handles network errors gracefully
/// - Ensures real-time updates using Firestore sync

class FriendsList extends StatelessWidget {
  const FriendsList({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppBloc>().state.user.id;
    return Scaffold(
      body: BlocProvider(
        create: (context) => FriendBloc(
          repository: context.read<FirebaseDatabaseRepository>(),
        )..add(LoadFriends(userId)),
        child: const FriendsListView(),
      ),
    );
  }
}

class FriendsListView extends StatelessWidget {
  const FriendsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppBloc>().state.user.id;
    return BlocBuilder<FriendBloc, FriendState>(
      builder: (context, state) {
        if (state is FriendsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is FriendsLoaded) {
          return state.friends.isEmpty
              ? const Center(child: Text('No friends found'))
              : ListView.builder(
                  itemCount: state.friends.length,
                  itemBuilder: (context, index) {
                    final friend = state.friends[index];
                    return ListTile(
                      title: Text(friend.username),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            _confirmRemoveFriend(context, friend, userId),
                      ),
                    );
                  },
                );
        } else if (state is FriendsError) {
          return const Center(child: Text('Failed to load friends'));
        }
        return const Center(child: Text('No friends found'));
      },
    );
  }

  void _confirmRemoveFriend(
    BuildContext context,
    FriendModel friend,
    String userId,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Friend'),
          content: Text('Are you sure you want to remove ${friend.username}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () {
                context
                    .read<FriendBloc>()
                    .add(RemoveFriend(userId, friend.userId));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
