import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

const _manaColors = <String, Color>{
  'W': Color(0xFFEFE8D2),
  'U': Color(0xFF378ADD),
  'B': Color(0xFF444441),
  'R': Color(0xFFE24B4A),
  'G': Color(0xFF639922),
};

class TrackingPreview extends StatelessWidget {
  const TrackingPreview({
    required this.damageClocks,
    required this.colorIdentity,
    super.key,
  });

  final int damageClocks;
  final List<String> colorIdentity;

  @override
  Widget build(BuildContext context) {
    final clockLabel = damageClocks == 1
        ? '1 commander-damage clock'
        : '$damageClocks commander-damage clocks';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This game will track',
            style: TextStyle(fontSize: 12, color: AppColors.neutral60),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.gavel, size: 17, color: AppColors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                clockLabel,
                style: const TextStyle(fontSize: 13, color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            key: const Key('tracking_preview_pips'),
            children: [
              const Text(
                'Colors',
                style: TextStyle(fontSize: 13, color: AppColors.neutral60),
              ),
              const SizedBox(width: AppSpacing.sm),
              for (final c in colorIdentity)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _manaColors[c] ?? AppColors.neutral60,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.neutral60.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              if (colorIdentity.isEmpty)
                const Text(
                  'Colorless',
                  style: TextStyle(fontSize: 12, color: AppColors.neutral60),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
