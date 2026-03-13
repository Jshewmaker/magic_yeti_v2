import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/friends_list/bloc/friend_list_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/player/player.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:magic_yeti/player/view/widgets/widgets.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

class CustomizePlayerPage extends StatelessWidget {
  const CustomizePlayerPage({
    required this.playerId,
    this.isRotated = false,
    super.key,
  });

  final String playerId;
  final bool isRotated;

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppBloc>().state.user.id;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PlayerCustomizationBloc(
            scryfallRepository: context.read<ScryfallRepository>(),
            firebaseDatabaseRepository:
                context.read<FirebaseDatabaseRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => FriendBloc(
            repository: context.read<FirebaseDatabaseRepository>(),
          )..add(LoadFriends(userId)),
        ),
      ],
      child: CustomizePlayerView(playerId: playerId, isRotated: isRotated),
    );
  }
}

class CustomizePlayerView extends StatefulWidget {
  const CustomizePlayerView({
    required this.playerId,
    this.isRotated = false,
    super.key,
  });

  final String playerId;
  final bool isRotated;

  @override
  State<CustomizePlayerView> createState() => _CustomizePlayerViewState();
}

class _CustomizePlayerViewState extends State<CustomizePlayerView> {
  late final TextEditingController _nameController;
  late final TextEditingController _searchController;
  final _scrollController = ScrollController();
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final player = context.read<PlayerRepository>().getPlayerById(
      widget.playerId,
    );
    _nameController = TextEditingController(text: player.name);
    _searchController = TextEditingController();
    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        _nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _nameController.text.length,
        );
      }
    });

    final isOwner = context.read<PlayerBloc>().state.player.firebaseId != null;
    context.read<PlayerCustomizationBloc>().add(
      UpdateAccountOwnership(isOwner: isOwner),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _save(BuildContext context, PlayerCustomizationState state) {
    String? firebaseId;
    if (state.selectedFriend != null && state.pinValidated) {
      firebaseId = state.selectedFriend!.userId;
    } else if (state.isAccountOwner) {
      firebaseId = context.read<AppBloc>().state.user.id;
    }

    context.read<PlayerBloc>().add(
      UpdatePlayerInfoEvent(
        playerName: _nameController.text,
        commander: state.commander,
        partner: state.hasPartner ? state.partner : null,
        playerId: widget.playerId,
        firebaseId: firebaseId,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerRepository>().getPlayerById(
      widget.playerId,
    );

    return BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
      builder: (context, state) {
        final commander = state.commander ?? player.commander;
        final partner = state.hasPartner
            ? (state.partner ?? player.partner)
            : null;
        return RotatedBox(
          quarterTurns: widget.isRotated ? 2 : 0,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actionsPadding: const EdgeInsets.only(right: AppSpacing.lg),
              actions: [
                FilledButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                  ),
                  onPressed: () => _save(context, state),
                ),
              ],
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                CommanderHeroBanner(
                  commander: commander,
                  partner: partner,
                  playerColor: player.color,
                ),
                ColoredBox(color: AppColors.black.withValues(alpha: 0.2)),
                SafeArea(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xxxlg * 2),
                      ),
                      SliverToBoxAdapter(
                        child: _FriendSelectionSection(
                          nameController: _nameController,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: PlayerNameRow(
                          textController: _nameController,
                          focusNode: _nameFocusNode,
                          showOnlyLegendary: state.showOnlyLegendary,
                          hasPartner: state.hasPartner,
                          isReadOnly: state.selectedFriend != null &&
                              state.pinValidated,
                        ),
                      ),
                      if (state.hasPartner) ...[
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.xs),
                        ),
                        SliverToBoxAdapter(
                          child: CommanderSlotSelector(
                            selectingPartner: state.selectingPartner,
                            searchTextController: _searchController,
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.sm),
                      ),
                      SliverToBoxAdapter(
                        child: CommanderSearchBar(
                          textController: _searchController,
                          selectingPartner: state.selectingPartner,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.sm),
                      ),
                      CommanderCardGrid(
                        scrollController: _scrollController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FriendSelectionSection extends StatelessWidget {
  const _FriendSelectionSection({required this.nameController});

  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final customState = context.watch<PlayerCustomizationBloc>().state;
    final friendState = context.watch<FriendBloc>().state;
    final selectedFriend = customState.selectedFriend;

    if (selectedFriend != null && customState.pinValidated) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xlg),
        child: Row(
          children: [
            const Icon(Icons.person, color: AppColors.green),
            const SizedBox(width: AppSpacing.sm),
            Text(
              context.l10n.linkedToFriend(selectedFriend.username),
              style: const TextStyle(color: AppColors.green),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                context
                    .read<PlayerCustomizationBloc>()
                    .add(const ClearFriend());
                nameController.clear();
              },
              child: Text(context.l10n.clearButtonText),
            ),
          ],
        ),
      );
    }

    if (friendState is! FriendsLoaded || friendState.friends.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xlg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.selectFriendLabel,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral60,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: friendState.friends.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final friend = friendState.friends[index];
                return ActionChip(
                  avatar: const Icon(Icons.person, size: 18),
                  label: Text(friend.username),
                  onPressed: () => _showPinDialog(
                    context,
                    friend,
                    nameController,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  void _showPinDialog(
    BuildContext context,
    FriendModel friend,
    TextEditingController nameController,
  ) {
    final pinController = TextEditingController();
    final bloc = context.read<PlayerCustomizationBloc>();

    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.verifyFriendTitle(friend.username)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.enterPinPrompt),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancelTextButton),
            ),
            FilledButton(
              onPressed: () async {
                final pin = pinController.text;
                if (pin.length != 4) return;

                bloc
                  ..add(SelectFriend(friend: friend))
                  ..add(
                    ValidatePin(
                      pin: pin,
                      friendUserId: friend.userId,
                    ),
                  );

                nameController.text = friend.username;
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.verifyButtonText),
            ),
          ],
        );
      },
    ).then((_) => pinController.dispose());
  }
}
