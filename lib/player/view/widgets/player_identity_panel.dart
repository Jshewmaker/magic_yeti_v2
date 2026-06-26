import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/widgets/tracking_preview.dart';

class PlayerIdentityPanel extends StatelessWidget {
  const PlayerIdentityPanel({
    required this.nameController,
    required this.nameFocusNode,
    required this.playerColor,
    required this.onSave,
    super.key,
  });

  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final int playerColor;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
      builder: (context, state) {
        final isLinked =
            state.selectedFriend != null && state.pinValidated;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Color(playerColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      focusNode: nameFocusNode,
                      readOnly: isLinked,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        hintText: 'Player name',
                        prefixIcon: Icon(
                          isLinked ? Icons.link : Icons.edit,
                          color:
                              isLinked ? AppColors.green : AppColors.neutral60,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _FriendLinkRow(isLinked: isLinked),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Commander',
                style: TextStyle(fontSize: 12, color: AppColors.neutral60),
              ),
              const SizedBox(height: AppSpacing.xs),
              _SecondCardSummary(state: state),
              const Spacer(),
              TrackingPreview(
                damageClocks: state.damageClocks,
                colorIdentity: state.colorIdentity,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Save player'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
                onPressed: onSave,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SecondCardSummary extends StatelessWidget {
  const _SecondCardSummary({required this.state});

  final PlayerCustomizationState state;

  @override
  Widget build(BuildContext context) {
    final commanderName = state.commander?.name ?? 'No commander selected';
    final second = state.partner ?? state.background;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          commanderName,
          style: const TextStyle(color: AppColors.white, fontSize: 15),
        ),
        if (second != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  state.partner != null ? Icons.people : Icons.auto_awesome,
                  size: 14,
                  color: AppColors.neutral60,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    second.name,
                    style: const TextStyle(
                      color: AppColors.neutral60,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  color: AppColors.neutral60,
                  onPressed: () => context
                      .read<PlayerCustomizationBloc>()
                      .add(const SecondCardCleared()),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FriendLinkRow extends StatelessWidget {
  const _FriendLinkRow({required this.isLinked});

  final bool isLinked;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlayerCustomizationBloc>().state;
    if (isLinked) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: AppColors.green, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Linked to ${state.selectedFriend?.username ?? ''}',
                style: const TextStyle(color: AppColors.white, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => context
                  .read<PlayerCustomizationBloc>()
                  .add(const ClearFriend()),
              child: const Text('Unlink'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
