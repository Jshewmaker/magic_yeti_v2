import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list/bloc/friend_list_bloc.dart';
import 'package:magic_yeti/friends_list/widgets/friend_card.dart';

class FriendsList extends StatelessWidget {
  const FriendsList({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppBloc>().state.user.id;
    return BlocProvider(
      create: (context) => FriendBloc(
        repository: context.read<FirebaseDatabaseRepository>(),
      )..add(LoadFriends(userId)),
      child: const FriendsListView(),
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
          if (state.friends.isEmpty) {
            return const Center(
              child: Text(
                'No friends found',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: state.friends.length,
            itemBuilder: (context, index) {
              final friend = state.friends[index];
              return FriendCard(
                initial: friend.username.isNotEmpty
                    ? friend.username[0]
                    : '?',
                title: friend.username,
                subtitle: friend.friendCode,
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.neutral60,
                  ),
                  onPressed: () =>
                      _confirmRemoveFriend(context, friend, userId),
                ),
              );
            },
          );
        } else if (state is FriendsError) {
          return const Center(
            child: Text(
              'Failed to load friends',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          );
        }
        return const Center(
          child: Text(
            'No friends found',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        );
      },
    );
  }

  void _confirmRemoveFriend(
    BuildContext context,
    FriendModel friend,
    String userId,
  ) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Remove Friend',
            style: TextStyle(color: AppColors.white),
          ),
          content: Text(
            'Are you sure you want to remove ${friend.username}?',
            style: const TextStyle(color: AppColors.neutral60),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.neutral60),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Remove',
                style: TextStyle(color: AppColors.red),
              ),
              onPressed: () {
                context
                    .read<FriendBloc>()
                    .add(RemoveFriend(userId, friend.userId));
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
        },
      ),
    );
  }
}
