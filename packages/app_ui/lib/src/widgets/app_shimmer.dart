import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// {@template app_shimmer}
/// Wraps [child] in a themed shimmer sweep, used for skeleton loading states.
///
/// Compose skeleton layouts from [SkeletonBone]s and wrap the whole layout in a
/// single [AppShimmer] so one synchronized sweep animates across every bone.
/// {@endtemplate}
class AppShimmer extends StatelessWidget {
  /// {@macro app_shimmer}
  const AppShimmer({
    required this.child,
    this.enabled = true,
    super.key,
  });

  /// The skeleton layout to animate.
  final Widget child;

  /// When false the [child] is rendered without the shimmer animation.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBase,
      highlightColor: AppColors.skeletonHighlight,
      child: child,
    );
  }
}
