import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/blocked_users/view/blocked_users_page.dart';
import 'package:magic_yeti/friends_list/friends_list/friends_list.dart';
import 'package:magic_yeti/friends_list/requests/friend_request_page.dart';
import 'package:magic_yeti/friends_list/search_user/search_user_page.dart';
import 'package:magic_yeti/l10n/l10n.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});
  factory FriendsListPage.pageBuilder(_, __) {
    return const FriendsListPage(key: Key('friends_list_page'));
  }

  static const routeName = 'friendsListPage';
  static const routePath = '/friendsListPage';

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  int _requestCount = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRequestCount());
  }

  Future<void> _loadRequestCount() async {
    final userId = context.read<AppBloc>().state.user.id;
    final db = context.read<FirebaseDatabaseRepository>();
    try {
      final requests = await db.getFriendRequests(userId);
      if (mounted) {
        setState(() => _requestCount = requests.length);
      }
    } on Exception catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.quaternary,
          iconTheme: const IconThemeData(
            color: AppColors.onSurfaceVariant,
          ),
          title: Text(
            l10n.friendsTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.block),
              tooltip: l10n.blockedUsersTitle,
              onPressed: () => context.push(BlockedUsersPage.routePath),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.friendsTitle),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.friendRequestsTitle),
                    if (_requestCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_requestCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            indicatorColor: AppColors.tertiary,
            labelColor: AppColors.onSurfaceVariant,
            unselectedLabelColor: AppColors.neutral60,
          ),
        ),
        body: const TabBarView(
          children: [
            FriendsList(),
            FriendRequestsPage(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          foregroundColor: AppColors.white,
          backgroundColor: AppColors.tertiary,
          onPressed: () => context.push(SearchUserPage.routePath),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
