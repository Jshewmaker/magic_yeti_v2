import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// Skeleton placeholder for the match history list, shown while games load.
///
/// Mirrors the layout of the real `MatchHistoryListItem` cards (a large winner
/// thumbnail, a column of runner-up thumbnails, and stacked detail lines) so
/// the transition to real content is seamless.
class MatchHistorySkeleton extends StatelessWidget {
  /// {@macro match_history_skeleton}
  const MatchHistorySkeleton({this.itemCount = 5, super.key});

  /// Number of placeholder cards to render.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: itemCount,
        itemBuilder: (context, index) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: AppColors.skeletonBase,
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Winner thumbnail.
            SkeletonBone(
              width: 160,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            SizedBox(width: 5),
            // Runner-up thumbnails column.
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 1),
                      child: SkeletonBone(borderRadius: BorderRadius.zero),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 1),
                      child: SkeletonBone(borderRadius: BorderRadius.zero),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 1),
                      child: SkeletonBone(borderRadius: BorderRadius.zero),
                    ),
                  ),
                ],
              ),
            ),
            // Detail lines.
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBone(width: 120, height: 20),
                    SizedBox(height: 6),
                    SkeletonBone(width: 90, height: 14),
                    Spacer(),
                    SkeletonBone(width: 100, height: 12),
                    SizedBox(height: 8),
                    SkeletonBone(width: 70, height: 12),
                    SizedBox(height: 8),
                    SkeletonBone(width: 80, height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
