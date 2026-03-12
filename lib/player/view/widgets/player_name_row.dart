import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';

class PlayerNameRow extends StatelessWidget {
  const PlayerNameRow({
    required this.textController,
    required this.showOnlyLegendary,
    required this.hasPartner,
    this.focusNode,
    super.key,
  });

  final TextEditingController textController;
  final FocusNode? focusNode;
  final bool showOnlyLegendary;
  final bool hasPartner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xlg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: 'Player name',
                prefixIcon:
                    const Icon(Icons.edit, color: AppColors.neutral60),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          FilterChip(
            selected: showOnlyLegendary,
            label: const Text('Legendary Only'),
            avatar: Icon(
              Icons.auto_awesome,
              size: 18,
              color: showOnlyLegendary
                  ? AppColors.secondary
                  : AppColors.neutral60,
            ),
            selectedColor: AppColors.secondary.withAlpha(40),
            checkmarkColor: AppColors.secondary,
            side: BorderSide(
              color: showOnlyLegendary
                  ? AppColors.secondary
                  : AppColors.neutral60.withAlpha(80),
            ),
            onSelected: (value) {
              context.read<PlayerCustomizationBloc>().add(
                    UpdateCommanderFilters(
                      showOnlyLegendary: value,
                      hasPartner: hasPartner,
                    ),
                  );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          FilterChip(
            selected: hasPartner,
            label: const Text('Has Partner'),
            avatar: Icon(
              Icons.people_outline,
              size: 18,
              color: hasPartner ? AppColors.secondary : AppColors.neutral60,
            ),
            selectedColor: AppColors.secondary.withAlpha(40),
            checkmarkColor: AppColors.secondary,
            side: BorderSide(
              color: hasPartner
                  ? AppColors.secondary
                  : AppColors.neutral60.withAlpha(80),
            ),
            onSelected: (value) {
              context.read<PlayerCustomizationBloc>().add(
                    UpdateCommanderFilters(
                      showOnlyLegendary: showOnlyLegendary,
                      hasPartner: value,
                    ),
                  );
            },
          ),
        ],
      ),
    );
  }
}
