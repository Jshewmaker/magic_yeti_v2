import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// {@template skeleton_bone}
/// A single grey "bone" used to compose skeleton loading placeholders.
///
/// Compose bones inside an [AppShimmer] so a single shimmer sweep animates
/// across all of them together, rather than animating each bone separately.
/// {@endtemplate}
class SkeletonBone extends StatelessWidget {
  /// {@macro skeleton_bone}
  const SkeletonBone({
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.shape = BoxShape.rectangle,
    super.key,
  });

  /// Width of the bone. When null the bone sizes to its parent constraints.
  final double? width;

  /// Height of the bone. When null the bone sizes to its parent constraints.
  final double? height;

  /// Corner radius of the bone. Ignored when [shape] is [BoxShape.circle].
  final BorderRadiusGeometry borderRadius;

  /// Shape of the bone. Use [BoxShape.circle] for avatar placeholders.
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : borderRadius,
      ),
    );
  }
}
