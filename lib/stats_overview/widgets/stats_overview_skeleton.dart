import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:magic_yeti/app/utils/device_info_provider.dart';

/// Skeleton placeholder for the stats overview, shown while stats compile.
///
/// Mirrors the real layout: a right-aligned time-range control and a 3-column
/// grid of `StatsWidget`-shaped tiles, keeping the same structure so there is
/// no layout jump when the real data arrives.
class StatsOverviewSkeleton extends StatelessWidget {
  /// {@macro stats_overview_skeleton}
  const StatsOverviewSkeleton({this.itemCount = 9, super.key});

  /// Number of placeholder stat tiles to render.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceInfoProvider.of(context).isPhone;
    return AppShimmer(
      child: Column(
        children: [
          // Time-range dropdown placeholder.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: SkeletonBone(width: 120, height: 24),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisSpacing: 50,
              childAspectRatio: isPhone ? .8 : 1.2,
              mainAxisSpacing: 10,
              crossAxisCount: 3,
              children: List.generate(
                itemCount,
                (_) => const _StatTileSkeleton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTileSkeleton extends StatelessWidget {
  const _StatTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SkeletonBone(width: 60, height: 34),
        SizedBox(height: 10),
        SkeletonBone(width: 72, height: 14),
      ],
    );
  }
}
