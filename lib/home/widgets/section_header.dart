import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';

/// Header bar used to title the home screen sections, with an optional
/// trailing action button.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.onMorePressed,
    this.icon,
    this.showBadge = false,
  });

  final String title;
  final VoidCallback? onMorePressed;

  /// Optional icon for the trailing action button. When provided, this icon is
  /// always shown (e.g. a friends icon for opening the friends list). When
  /// null, the button shows the user's profile photo, falling back to a
  /// single-person icon.
  final IconData? icon;

  /// Whether to overlay a [NotificationDot] on the trailing action button,
  /// marking unseen items behind it. Only honoured when [icon] is set.
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppBloc>().state.user;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.quaternary,
        border: Border(
          right: BorderSide(width: 3, color: AppColors.background),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (onMorePressed != null)
            if (icon != null)
              BadgedIconButton(
                icon: icon!,
                color: AppColors.onSurfaceVariant,
                showBadge: showBadge,
                onPressed: onMorePressed,
              )
            else if (user.photo == null || user.photo!.isEmpty)
              IconButton(
                onPressed: onMorePressed,
                icon: const Icon(
                  Icons.account_circle_sharp,
                  color: AppColors.onSurfaceVariant,
                ),
              )
            else
              InkWell(
                onTap: onMorePressed,
                child: ClipOval(
                  child: Image.network(
                    user.photo!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const AppShimmer(
                        child: SkeletonBone(
                          width: 40,
                          height: 40,
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_circle_sharp,
                      color: AppColors.onSurfaceVariant,
                      size: 40,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
