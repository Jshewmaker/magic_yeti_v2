import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friend_stats/friend_stats.dart';
import 'package:magic_yeti/friends_list/friend_stats/view/friend_stats_tiles.dart';
import 'package:magic_yeti/home/match_history_bloc/match_history_bloc.dart';
import 'package:magic_yeti/stats_overview/stats_overview.dart';

/// Head-to-head stats between the signed-in user and one friend, over the pods
/// they have played together.
///
/// Reached by tapping a friend in the friends list. The [FriendModel] is passed
/// via GoRouter `extra` for the header; stats are computed from [friendId] and
/// the app-wide match history, so the page still renders if `extra` is absent.
class FriendStatsPage extends StatelessWidget {
  const FriendStatsPage({
    required this.friendId,
    this.friend,
    super.key,
  });

  factory FriendStatsPage.pageBuilder(_, GoRouterState state) {
    return FriendStatsPage(
      friendId: state.pathParameters['friendId']!,
      friend: state.extra is FriendModel ? state.extra! as FriendModel : null,
    );
  }

  final String friendId;
  final FriendModel? friend;

  static const routeName = 'friend_stats_page';
  static String get routePath => '/friend_stats_page/:friendId';
  static String path({required String friendId}) =>
      '/friend_stats_page/$friendId';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FriendStatsBloc(),
      child: _FriendStatsView(friendId: friendId, friend: friend),
    );
  }
}

class _FriendStatsView extends StatefulWidget {
  const _FriendStatsView({required this.friendId, this.friend});

  final String friendId;
  final FriendModel? friend;

  @override
  State<_FriendStatsView> createState() => _FriendStatsViewState();
}

class _FriendStatsViewState extends State<_FriendStatsView> {
  @override
  void initState() {
    super.initState();
    final matchHistory = context.read<MatchHistoryBloc>().state;
    if (matchHistory.status == MatchHistoryStatus.loadingHistorySuccess ||
        matchHistory.status == MatchHistoryStatus.gameNotFound) {
      _compile(matchHistory.games);
    }
  }

  void _compile(List<GameModel> games) {
    context.read<FriendStatsBloc>().add(
      CompileFriendStats(
        myId: context.read<AppBloc>().state.user.id,
        friendId: widget.friendId,
        games: games,
      ),
    );
  }

  void _onRangeChanged(StatsTimeRange? range) {
    if (range == null) return;
    context.read<FriendStatsBloc>().add(FriendStatsRangeChanged(range));
  }

  String get _friendName => widget.friend?.username ?? 'Friend';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('$_friendName · Head to Head'),
      ),
      body: BlocListener<MatchHistoryBloc, MatchHistoryState>(
        listenWhen: (previous, current) =>
            !identical(previous.games, current.games),
        listener: (context, state) => _compile(state.games),
        child: BlocBuilder<FriendStatsBloc, FriendStatsState>(
          builder: (context, state) {
            return switch (state) {
              FriendStatsLoaded(:final stats, :final range) => _FriendStatsBody(
                friendName: _friendName,
                friend: widget.friend,
                stats: stats,
                range: range,
                onRangeChanged: _onRangeChanged,
              ),
              FriendStatsFailure() => const Center(
                child: Text('Could not load these stats.'),
              ),
              _ => const StatsOverviewSkeleton(itemCount: 6),
            };
          },
        ),
      ),
    );
  }
}

class _FriendStatsBody extends StatelessWidget {
  const _FriendStatsBody({
    required this.friendName,
    required this.friend,
    required this.stats,
    required this.range,
    required this.onRangeChanged,
  });

  final String friendName;
  final FriendModel? friend;
  final FriendHeadToHead stats;
  final StatsTimeRange range;
  final ValueChanged<StatsTimeRange?> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    // No shared pods in the full history: the "go tag them" empty state. There
    // is nothing to filter, so the dropdown is omitted here.
    if (stats.sharedPods == 0 && range == StatsTimeRange.allTime) {
      return _EmptyState(friendName: friendName);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _RangeDropdown(range: range, onChanged: onRangeChanged),
          ),
          const SizedBox(height: 8),
          _Header(friendName: friendName, friend: friend, stats: stats),
          const SizedBox(height: 16),
          if (stats.sharedPods == 0)
            const _NoPodsInRange()
          else ...[
            LedgerHeroTile(stats: stats, friendName: friendName),
            const SizedBox(height: 16),
            // The grid is intrinsically sized inside a scroll view. Tight
            // spacing keeps the cards close together; the aspect ratio gives
            // each cell enough height to fit its title/value/caption without
            // overflow even for the longest content (a long commander name
            // plus the two damage tiles) — FriendStatCard has no flex child,
            // so AutoSizeText shrinks by width, not by the cell's height.
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
              children: buildFriendStatTiles(stats),
            ),
          ],
        ],
      ),
    );
  }
}

/// Right-aligned time-range selector, styled like the home stats dropdown.
class _RangeDropdown extends StatelessWidget {
  const _RangeDropdown({required this.range, required this.onChanged});

  final StatsTimeRange range;
  final ValueChanged<StatsTimeRange?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<StatsTimeRange>(
      value: range,
      dropdownColor: Colors.grey[900],
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
      underline: Container(height: 1, color: Colors.blueGrey.withAlpha(100)),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
      items: StatsTimeRange.values
          .map(
            (r) => DropdownMenuItem<StatsTimeRange>(
              value: r,
              child: Text(r.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// Shown when the selected range has no shared pods but the friendship does —
/// distinct from [_EmptyState], and leaves the dropdown visible to widen out.
class _NoPodsInRange extends StatelessWidget {
  const _NoPodsInRange();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          const Icon(
            Icons.filter_alt_off_outlined,
            size: 48,
            color: AppColors.tertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'No shared pods in this range',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Try a wider time range.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.friendName,
    required this.friend,
    required this.stats,
  });

  final String friendName;
  final FriendModel? friend;
  final FriendHeadToHead stats;

  @override
  Widget build(BuildContext context) {
    final imageUrl = friend?.profilePictureUrl ?? '';
    final since = stats.firstPlayedTogether;
    final subtitle = since == null
        ? '${stats.sharedPods} pods together'
        : '${stats.sharedPods} pods together · since '
              '${DateFormat('MMM yyyy').format(since)}';

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.tertiary,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty
              ? Text(
                  friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                friendName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral60),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.friendName});

  final String friendName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 64,
              color: AppColors.tertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No shared pods yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Once you and $friendName play a pod together it'll show up "
              'here. Played before adding each other? Open a match from your '
              'history and tag $friendName into their seat.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
