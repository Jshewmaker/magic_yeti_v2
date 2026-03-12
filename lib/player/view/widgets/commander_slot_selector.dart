import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';

class CommanderSlotSelector extends StatelessWidget {
  const CommanderSlotSelector({
    required this.selectingPartner,
    required this.searchTextController,
    super.key,
  });

  final bool selectingPartner;
  final TextEditingController searchTextController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xlg,
        vertical: AppSpacing.sm,
      ),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            label: Text('Commander'),
            icon: Icon(Icons.shield_outlined),
          ),
          ButtonSegment(
            value: true,
            label: Text('Partner'),
            icon: Icon(Icons.people_outline),
          ),
        ],
        selected: {selectingPartner},
        onSelectionChanged: (selection) {
          context.read<PlayerCustomizationBloc>()
            ..add(UpdatePartnerSelection(selectingPartner: selection.first))
            ..add(const ClearCardList());
          searchTextController.clear();
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.secondary.withAlpha(40);
            }
            return AppColors.quaternary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.secondary;
            }
            return AppColors.neutral60;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: AppColors.secondary.withAlpha(80)),
          ),
        ),
      ),
    );
  }
}
