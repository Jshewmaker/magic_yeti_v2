import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/friends_list/friends_list/friends_list.dart';
import 'package:magic_yeti/friends_list/requests/friend_request_page.dart';
import 'package:magic_yeti/friends_list/search_user/search_user_page.dart';
import 'package:magic_yeti/l10n/l10n.dart';

class FriendsListPage extends StatelessWidget {
  const FriendsListPage({super.key});
  factory FriendsListPage.pageBuilder(_, __) {
    return const FriendsListPage(key: Key('friends_list_page'));
  }

  static const routeName = 'friendsListPage';
  static const routePath = '/friendsListPage';
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.quaternary,
          title: Text(
            l10n.friendsTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.friendsTitle),
              Tab(text: l10n.friendRequestsTitle),
            ],
            indicatorColor: AppColors.tertiary,
            labelColor: AppColors.onSurfaceVariant,
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
          onPressed: () => context.go(SearchUserPage.routePath),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
