import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';

class CommanderSearchBar extends StatelessWidget {
  const CommanderSearchBar({
    required this.textController,
    required this.selectingPartner,
    super.key,
  });

  final TextEditingController textController;
  final bool selectingPartner;

  void _search(BuildContext context) {
    FocusScope.of(context).unfocus();
    context.read<PlayerCustomizationBloc>().add(
          CardListRequested(cardName: textController.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
              autocorrect: false,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(context),
              decoration: InputDecoration(
                hintText: selectingPartner
                    ? 'Search for partner commander...'
                    : l10n.searchCommanderHintText,
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.neutral60),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            icon: const Icon(Icons.search, size: 18),
            label: Text(l10n.searchButtonText),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
            onPressed: () => _search(context),
          ),
        ],
      ),
    );
  }
}
