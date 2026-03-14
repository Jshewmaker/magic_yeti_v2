import 'dart:async';

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
                        child: _FriendSection(
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
                          isLinkedToFriend: state.selectedFriend != null &&
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

class _FriendSection extends StatelessWidget {
  const _FriendSection({required this.nameController});

  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final customState = context.watch<PlayerCustomizationBloc>().state;
    final friendState = context.watch<FriendBloc>().state;
    final isLinked =
        customState.selectedFriend != null && customState.pinValidated;

    // Hide section if no friends loaded and no friend selected
    final hasFriends =
        friendState is FriendsLoaded && friendState.friends.isNotEmpty;
    if (!hasFriends && !isLinked) {
      return const SizedBox.shrink();
    }

    final friends =
        friendState is FriendsLoaded ? friendState.friends : <FriendModel>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xlg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with optional Clear button
          Row(
            children: [
              Text(
                context.l10n.selectFriendLabel,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral60,
                ),
              ),
              const Spacer(),
              if (isLinked)
                TextButton(
                  onPressed: () {
                    context
                        .read<PlayerCustomizationBloc>()
                        .add(const ClearFriend());
                    nameController.clear();
                  },
                  child: Text(
                    context.l10n.clearButtonText,
                    style: const TextStyle(color: AppColors.neutral60),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Friend list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: friends.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final friend = friends[index];
                final isSelected = isLinked &&
                    customState.selectedFriend?.userId == friend.userId;
                return _FriendTile(
                  friend: friend,
                  isSelected: isSelected,
                  onTap: isSelected
                      ? null
                      : () => _showPinDialog(context, friend),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context, FriendModel friend) {
    final pinController = TextEditingController();
    final bloc = context.read<PlayerCustomizationBloc>();
    final l10n = context.l10n;

    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return BlocProvider.value(
            value: bloc,
            child: BlocListener<PlayerCustomizationBloc,
                PlayerCustomizationState>(
              listenWhen: (previous, current) =>
                  previous.pinValidated != current.pinValidated ||
                  previous.pinError != current.pinError,
              listener: (listenerContext, state) {
                if (state.pinValidated) {
                  // PIN succeeded — select friend, populate name, close
                  bloc.add(SelectFriend(friend: friend));
                  nameController.text = friend.username;
                  Navigator.pop(listenerContext);
                }
                // pinError is shown reactively via the StatefulBuilder below
              },
              child: StatefulBuilder(
                builder: (dialogContext, setDialogState) {
                  return AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Text(
                      l10n.verifyFriendTitle(friend.username),
                      style: const TextStyle(color: AppColors.white),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.enterPinPrompt,
                          style:
                              const TextStyle(color: AppColors.neutral60),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        BlocBuilder<PlayerCustomizationBloc,
                            PlayerCustomizationState>(
                          buildWhen: (previous, current) =>
                              previous.pinError != current.pinError,
                          builder: (context, state) {
                            return TextField(
                              controller: pinController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                letterSpacing: 8,
                                color: AppColors.white,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surface,
                                counterText: '',
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.neutral60,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.tertiary,
                                  ),
                                ),
                                errorBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.red,
                                  ),
                                ),
                                focusedErrorBorder:
                                    const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.red,
                                  ),
                                ),
                                errorText: state.pinError.isNotEmpty
                                    ? state.pinError
                                    : null,
                                errorStyle: const TextStyle(
                                  color: AppColors.red,
                                ),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            );
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          l10n.cancelTextButton,
                          style:
                              const TextStyle(color: AppColors.neutral60),
                        ),
                      ),
                      FilledButton(
                        onPressed: pinController.text.length == 4
                            ? () {
                                bloc.add(
                                  ValidatePin(
                                    pin: pinController.text,
                                    friendUserId: friend.userId,
                                  ),
                                );
                              }
                            : null,
                        child: Text(l10n.verifyButtonText),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.isSelected,
    required this.onTap,
  });

  final FriendModel friend;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
            color: isSelected
                ? AppColors.tertiary
                : AppColors.neutral60.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Profile picture or first-letter fallback
            if (friend.profilePictureUrl.isNotEmpty)
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.tertiary,
                backgroundImage: NetworkImage(friend.profilePictureUrl),
                onBackgroundImageError: (_, _) {},
              )
            else
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.tertiary,
                child: Text(
                  friend.username.isNotEmpty
                      ? friend.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                friend.username,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.green,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
