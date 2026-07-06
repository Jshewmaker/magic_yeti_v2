import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list/bloc/friend_list_bloc.dart';
import 'package:magic_yeti/friends_list/widgets/friend_card.dart';
import 'package:magic_yeti/l10n/arb/app_localizations.dart';
import 'package:magic_yeti/l10n/l10n.dart';

enum _FriendCardAction { remove, block }

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
    final l10n = context.l10n;
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
                trailing: PopupMenuButton<_FriendCardAction>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.neutral60,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _FriendCardAction.remove:
                        _confirmRemoveFriend(context, friend, userId, l10n);
                      case _FriendCardAction.block:
                        _confirmBlockFriend(context, friend, userId, l10n);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _FriendCardAction.remove,
                      child: Text(l10n.removeFriendAction),
                    ),
                    PopupMenuItem(
                      value: _FriendCardAction.block,
                      child: Text(l10n.blockUserAction),
                    ),
                  ],
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
    AppLocalizations l10n,
  ) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l10n.removeFriendConfirmTitle(friend.username),
              style: const TextStyle(color: AppColors.white),
            ),
            content: Text(
              l10n.removeFriendConfirmBody,
              style: const TextStyle(color: AppColors.neutral60),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  l10n.cancelTextButton,
                  style: const TextStyle(color: AppColors.neutral60),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: Text(
                  l10n.removeFriendAction,
                  style: const TextStyle(color: AppColors.red),
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

  void _confirmBlockFriend(
    BuildContext context,
    FriendModel friend,
    String userId,
    AppLocalizations l10n,
  ) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l10n.blockUserConfirmTitle(friend.username),
              style: const TextStyle(color: AppColors.white),
            ),
            content: Text(
              l10n.blockUserConfirmBody,
              style: const TextStyle(color: AppColors.neutral60),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  l10n.cancelTextButton,
                  style: const TextStyle(color: AppColors.neutral60),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: Text(
                  l10n.blockUserAction,
                  style: const TextStyle(color: AppColors.red),
                ),
                onPressed: () {
                  context.read<FriendBloc>().add(
                        BlockFriend(
                          userId,
                          BlockedUserModel(
                            userId: friend.userId,
                            username: friend.username,
                            imageUrl: friend.profilePictureUrl,
                            friendCode: friend.friendCode,
                          ),
                        ),
                      );
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
