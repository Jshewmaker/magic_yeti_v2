import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list_page.dart';
import 'package:magic_yeti/friends_list/requests/bloc/friend_request_bloc.dart';
import 'package:magic_yeti/home/widgets/widgets.dart';
import 'package:magic_yeti/l10n/l10n.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  factory HomePage.pageBuilder(_, __) {
    return const HomePage(key: Key('home_page'));
  }

  static const routeName = '/';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    unawaited(_ensureFriendCodeSafetyNet());
  }

  /// Minimal safety net: if onboarding was completed but friend code
  /// is somehow missing, regenerate it silently.
  Future<void> _ensureFriendCodeSafetyNet() async {
    final appState = context.read<AppBloc>().state;
    if (appState.status != AppStatus.authenticated) return;

    final db = context.read<FirebaseDatabaseRepository>();
    final user = appState.user;

    final profile = await db.getUserProfileOnce(user.id);
    if (!mounted) return;

    if (profile != null && profile.friendCode == null) {
      final friendCode = await db.generateUniqueFriendCode();
      if (!mounted) return;
      await db.updateUserProfile(
        user.id,
        profile.copyWith(friendCode: friendCode),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceInfoProvider.of(context).isPhone;
    return OrientationLock(
      // Phones stay in portrait on the home screen; tablets are free.
      orientations: isPhone ? const [DeviceOrientation.portraitUp] : null,
      child: AdaptiveLayout(
        phone: (_) => const _PhoneHomeView(),
        tablet: (_) => const _TabletHomeView(),
      ),
    );
  }
}

class _TabletHomeView extends StatelessWidget {
  const _TabletHomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Row(
        children: [
          const Expanded(child: HomeSidePanel()),
          Expanded(
            child: Column(
              children: [
                BlocBuilder<FriendRequestBloc, FriendRequestState>(
                  builder: (context, state) => SectionHeader(
                    title: l10n.matchHistoryTitle,
                    icon: Icons.people,
                    showBadge: _hasPendingRequests(state),
                    onMorePressed: () =>
                        context.push(FriendsListPage.routePath),
                  ),
                ),
                const Expanded(
                  child: MatchHistoryPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: const AddMatchFab(),
      resizeToAvoidBottomInset: false,
    );
  }
}

class _PhoneHomeView extends StatelessWidget {
  const _PhoneHomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.quaternary,
          title: Text(
            'Magic Yeti',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.gameModeTitle),
              Tab(text: l10n.matchHistoryTitle),
            ],
            indicatorColor: AppColors.tertiary,
            labelColor: AppColors.onSurfaceVariant,
          ),
          actions: [
            BlocBuilder<FriendRequestBloc, FriendRequestState>(
              builder: (context, state) => BadgedIconButton(
                icon: Icons.people,
                showBadge: _hasPendingRequests(state),
                onPressed: () => context.push(FriendsListPage.routePath),
              ),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            HomeSidePanel(),
            MatchHistoryPanel(),
          ],
        ),
        floatingActionButton: const AddMatchFab(),
        resizeToAvoidBottomInset: false,
      ),
    );
  }
}

/// True when the signed-in user has at least one pending friend request.
///
/// Any non-loaded state (loading, error, the transient legacy-accept error)
/// reads as false: a dot that might be wrong sends the user to a page to find
/// nothing, which is worse than no dot.
bool _hasPendingRequests(FriendRequestState state) =>
    state is FriendRequestLoaded && state.requests.isNotEmpty;
