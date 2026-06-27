import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';

class CommanderSearchBar extends StatefulWidget {
  const CommanderSearchBar({
    required this.textController,
    required this.selectingPartner,
    this.searchBackgrounds = false,
    super.key,
  });

  final TextEditingController textController;
  final bool selectingPartner;
  final bool searchBackgrounds;

  @override
  State<CommanderSearchBar> createState() => _CommanderSearchBarState();
}

class _CommanderSearchBarState extends State<CommanderSearchBar> {
  /// Live search kicks in once the query is at least this many characters.
  static const _minQueryLength = 3;

  /// Wait briefly after the last keystroke before querying, so we don't fire a
  /// request on every character and trip Scryfall's rate limits.
  static const _debounce = Duration(milliseconds: 350);

  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _dispatchSearch() {
    context.read<PlayerCustomizationBloc>().add(
          CardListRequested(
            cardName: widget.textController.text,
            searchBackgrounds: widget.searchBackgrounds,
          ),
        );
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    if (value.trim().length < _minQueryLength) return;
    _debounceTimer = Timer(_debounce, _dispatchSearch);
  }

  void _searchNow() {
    _debounceTimer?.cancel();
    FocusScope.of(context).unfocus();
    _dispatchSearch();
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
              controller: widget.textController,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (_) => _searchNow(),
              decoration: InputDecoration(
                hintText: widget.selectingPartner
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
            onPressed: _searchNow,
          ),
        ],
      ),
    );
  }
}
