import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/blocked_users/bloc/blocked_users_bloc.dart';
import 'package:magic_yeti/friends_list/widgets/friend_card.dart';
import 'package:magic_yeti/l10n/l10n.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  factory BlockedUsersPage.pageBuilder(_, __) {
    return const BlockedUsersPage(key: Key('blocked_users_page'));
  }

  static const routeName = 'blockedUsersPage';
  static const routePath = '/blockedUsersPage';

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppBloc>().state.user.id;
    return BlocProvider(
      create: (context) => BlockedUsersBloc(
        repository: context.read<FirebaseDatabaseRepository>(),
      )..add(LoadBlockedUsers(userId)),
      child: const BlockedUsersView(),
    );
  }
}

class BlockedUsersView extends StatelessWidget {
  const BlockedUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.quaternary,
        iconTheme: const IconThemeData(
          color: AppColors.onSurfaceVariant,
        ),
        title: Text(
          l10n.blockedUsersTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: BlocBuilder<BlockedUsersBloc, BlockedUsersState>(
        builder: (context, state) {
          if (state is BlockedUsersLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BlockedUsersLoaded) {
            if (state.blockedUsers.isEmpty) {
              return Center(
                child: Text(
                  l10n.blockedUsersEmpty,
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: state.blockedUsers.length,
              itemBuilder: (context, index) {
                final blockedUser = state.blockedUsers[index];
                return FriendCard(
                  initial: blockedUser.username.isNotEmpty
                      ? blockedUser.username[0]
                      : '?',
                  title: blockedUser.username,
                  trailing: TextButton(
                    onPressed: () =>
                        _confirmUnblock(context, blockedUser),
                    child: Text(
                      l10n.unblockUserAction,
                      style: const TextStyle(color: AppColors.tertiary),
                    ),
                  ),
                );
              },
            );
          } else if (state is BlockedUsersError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _confirmUnblock(BuildContext context, BlockedUserModel blockedUser) {
    final l10n = context.l10n;
    final userId = context.read<AppBloc>().state.user.id;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l10n.unblockUserAction,
              style: const TextStyle(color: AppColors.white),
            ),
            content: Text(
              'Are you sure you want to unblock ${blockedUser.username}?',
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
                child: Text(
                  l10n.unblockUserAction,
                  style: const TextStyle(color: AppColors.tertiary),
                ),
                onPressed: () {
                  context.read<BlockedUsersBloc>().add(
                        UnblockUser(userId, blockedUser.userId),
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
