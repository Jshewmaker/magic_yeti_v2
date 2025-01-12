import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';

class AccountOwnershipWidget extends StatelessWidget {
  const AccountOwnershipWidget({
    required this.isAccountOwner,
    super.key,
  });

  final bool isAccountOwner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is my account',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Link this player to your account to track stats and history',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: isAccountOwner,
            onChanged: (value) {
              context.read<PlayerCustomizationBloc>().add(
                    UpdateAccountOwnership(isOwner: value),
                  );
            },
          ),
        ],
      ),
    );
  }
}
