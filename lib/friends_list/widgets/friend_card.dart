import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// A styled card for displaying friend-related items.
///
/// Used across friends list, friend requests, and search results
/// for consistent elevated card styling.
class FriendCard extends StatelessWidget {
  const FriendCard({
    required this.initial,
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String initial;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Tapping the card body (outside [trailing]) invokes this, if provided.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.tertiary,
                  child: Text(
                    initial.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.neutral60,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
