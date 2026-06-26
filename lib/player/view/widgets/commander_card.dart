import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:player_repository/player_repository.dart';

class CommanderCard extends StatelessWidget {
  const CommanderCard({
    required this.commander,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.isSelected = false,
    super.key,
  });

  final Commander commander;
  final bool isFavorite;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: ColoredBox(
          color: AppColors.quaternary,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (commander.imageUrl.isNotEmpty)
                Image.network(
                  commander.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(
                    color: AppColors.neutral60,
                    child: Center(child: Icon(Icons.broken_image)),
                  ),
                )
              else
                const ColoredBox(
                  color: AppColors.neutral60,
                  child: Center(child: Icon(Icons.image_not_supported)),
                ),
              if (isSelected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.secondary, width: 3),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: onToggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      size: 18,
                      color: isFavorite ? AppColors.secondary : AppColors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: AppColors.black.withValues(alpha: 0.55),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    commander.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
