import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/home/widgets/account_widget.dart';
import 'package:magic_yeti/home/widgets/game_mode_buttons.dart';
import 'package:magic_yeti/home/widgets/section_header.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/profile/view/profile_page.dart';

/// The game-mode + account panel of the home screen.
///
/// On tablets it fills the left half of the screen and carries its own
/// "Game Mode" header; on phones it is the first tab and the tab bar already
/// provides that label.
class HomeSidePanel extends StatelessWidget {
  const HomeSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPhone = DeviceInfoProvider.of(context).isPhone;
    final isAuthenticated =
        context.watch<AppBloc>().state.status == AppStatus.authenticated;
    return Column(
      children: [
        if (isPhone)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: GameModeButtons(),
          )
        else ...[
          SectionHeader(title: l10n.gameModeTitle),
          const GameModeButtons(),
        ],
        SectionHeader(
          title: isAuthenticated ? l10n.statsTitle : l10n.loginSignUpTitle,
          onMorePressed: isAuthenticated
              ? () => context.go(ProfilePage.routePath)
              : null,
        ),
        const Expanded(child: AccountWidget()),
      ],
    );
  }
}
