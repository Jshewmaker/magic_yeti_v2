import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
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
    super.key,
  });

  final String playerId;

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
            commanderLibraryRepository:
                context.read<CommanderLibraryRepository>(),
          )..add(const LibraryRequested()),
        ),
        BlocProvider(
          create: (context) => FriendBloc(
            repository: context.read<FirebaseDatabaseRepository>(),
          )..add(LoadFriends(userId)),
        ),
      ],
      child: CustomizePlayerView(playerId: playerId),
    );
  }
}

class CustomizePlayerView extends StatefulWidget {
  const CustomizePlayerView({
    required this.playerId,
    super.key,
  });

  final String playerId;

  @override
  State<CustomizePlayerView> createState() => _CustomizePlayerViewState();
}

class _CustomizePlayerViewState extends State<CustomizePlayerView> {
  late final TextEditingController _nameController;
  late final TextEditingController _searchController;
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

    final currentUserId = context.read<AppBloc>().state.user.id;
    final linkedFirebaseId = context.read<PlayerBloc>().state.player.firebaseId;
    if (linkedFirebaseId != null && linkedFirebaseId == currentUserId) {
      context.read<PlayerCustomizationBloc>().add(
        OwnerSelected(userId: currentUserId),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
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
        partner: state.partner,
        background: state.background,
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

    return MultiBlocListener(
      listeners: [
        BlocListener<FriendBloc, FriendState>(
          listenWhen: (previous, current) => current is FriendsLoaded,
          listener: (context, friendState) {
            final customState = context.read<PlayerCustomizationBloc>().state;
            if (customState.isAccountOwner ||
                customState.selectedFriend != null) {
              return;
            }
            final linkedFirebaseId =
                context.read<PlayerBloc>().state.player.firebaseId;
            if (linkedFirebaseId == null) return;
            final friends = (friendState as FriendsLoaded).friends;
            FriendModel? match;
            for (final f in friends) {
              if (f.userId == linkedFirebaseId) {
                match = f;
                break;
              }
            }
            if (match != null) {
              context.read<PlayerCustomizationBloc>().add(
                SelectFriend(friend: match),
              );
            }
          },
        ),
        BlocListener<PlayerCustomizationBloc, PlayerCustomizationState>(
          listenWhen: (previous, current) =>
              previous.isAccountOwner != current.isAccountOwner ||
              previous.ownerUsername != current.ownerUsername ||
              previous.selectedFriend != current.selectedFriend,
          listener: (context, state) {
            if (state.isAccountOwner) {
              final owner = state.ownerUsername;
              if (owner != null && owner.isNotEmpty) {
                _nameController.text = owner;
              }
            } else if (state.selectedFriend != null) {
              _nameController.text = state.selectedFriend!.username;
            } else {
              _nameController.clear();
            }
          },
        ),
      ],
      child: BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
        builder: (context, state) {
          final commander = state.commander ?? player.commander;
          return Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                CommanderHeroBanner(
                  commander: commander,
                  partner: state.partner,
                  background: state.background,
                  playerColor: player.color,
                ),
                ColoredBox(color: AppColors.black.withValues(alpha: 0.45)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 39,
                          child: _Panel(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  const _FriendSection(),
                                  PlayerIdentityPanel(
                                    nameController: _nameController,
                                    nameFocusNode: _nameFocusNode,
                                    playerColor: player.color,
                                    onSave: () => _save(context, state),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 61,
                          child: _Panel(
                            child: CommanderPickerPanel(
                              searchController: _searchController,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: child,
    );
  }
}

class _FriendSection extends StatefulWidget {
  const _FriendSection();

  @override
  State<_FriendSection> createState() => _FriendSectionState();
}

class _FriendSectionState extends State<_FriendSection> {
  int _resetNonce = 0;

  void _forceReset() {
    if (mounted) setState(() => _resetNonce++);
  }

  @override
  Widget build(BuildContext context) {
    final customState = context.watch<PlayerCustomizationBloc>().state;
    final friendState = context.watch<FriendBloc>().state;
    final appState = context.watch<AppBloc>().state;
    final isAnonymous = appState.status == AppStatus.anonymous;

    // Anonymous users have no friend graph to link against — the callable
    // backing this list requires an authenticated uid, so show intentional
    // copy instead of an empty/loading friend list.
    if (isAnonymous) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xlg,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          context.l10n.signInToLinkFriends,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.neutral60,
          ),
        ),
      );
    }

    final friends =
        friendState is FriendsLoaded ? friendState.friends : <FriendModel>[];
    final sortedFriends = List<FriendModel>.from(friends)
      ..sort(
        (a, b) =>
            a.username.toLowerCase().compareTo(b.username.toLowerCase()),
      );

    final currentUserId = appState.user.id;
    final confirmedValue = customState.isAccountOwner
        ? currentUserId
        : (customState.selectedFriend != null && customState.pinValidated
            ? customState.selectedFriend!.userId
            : null);

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
            width: double.infinity,
            child: DropdownMenu<String?>(
              key: ValueKey('$confirmedValue-$_resetNonce'),
              initialSelection: confirmedValue,
              enableFilter: true,
              enableSearch: true,
              // DropdownMenu.requestFocusOnTap defaults to false on mobile
              // platforms (iOS/Android/Fuchsia), which makes its internal
              // TextField readOnly — type-to-search silently does nothing
              // there without this. This app's primary targets are iOS and
              // Android (see CLAUDE.md), so enableFilter's whole point
              // (Step 7's "filters as you type... on a small simulated
              // device (e.g. iPhone SE)") requires this explicitly.
              requestFocusOnTap: true,
              hintText: context.l10n.notLinkedOptionLabel,
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: null,
                  label: context.l10n.notLinkedOptionLabel,
                ),
                DropdownMenuEntry(
                  value: currentUserId,
                  label: context.l10n.accountOwnerOptionLabel,
                ),
                ...sortedFriends.map(
                  (friend) => DropdownMenuEntry(
                    value: friend.userId,
                    label: friend.username,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == null) {
                  context.read<PlayerCustomizationBloc>().add(
                        const LinkCleared(),
                      );
                } else if (value == currentUserId) {
                  context.read<PlayerCustomizationBloc>().add(
                        OwnerSelected(userId: currentUserId),
                      );
                } else {
                  final friend = sortedFriends.firstWhere(
                    (f) => f.userId == value,
                  );
                  _showPinDialog(context, friend);
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  String? _pinErrorText(BuildContext context, PlayerCustomizationState state) {
    final l10n = context.l10n;
    return switch (state.pinFlowError) {
      PinFlowError.none => null,
      PinFlowError.incorrect =>
        l10n.pinIncorrectError(state.pinAttemptsRemaining),
      PinFlowError.lockedOut => l10n.pinLockedOutError(
          state.pinLockedUntil == null
              ? 15
              : (state.pinLockedUntil!
                          .difference(DateTime.now())
                          .inSeconds /
                      60)
                  .ceil()
                  .clamp(1, 15),
        ),
      PinFlowError.unavailable => l10n.pinUnavailableError,
      PinFlowError.notSet => l10n.pinNotSetError,
    };
  }

  void _showPinDialog(BuildContext context, FriendModel friend) {
    final pinController = TextEditingController();
    final bloc = context.read<PlayerCustomizationBloc>();
    final l10n = context.l10n;

    // Clear any stale error/lockout state left over from a previous
    // friend's dialog before this one opens.
    bloc.add(const ResetPinFlow());

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
                  previous.pinFlowError != current.pinFlowError,
              listener: (listenerContext, state) {
                if (state.pinValidated) {
                  // PIN succeeded — select friend, close. The page-level
                  // BlocListener in CustomizePlayerView.build() populates
                  // the name field once selectedFriend changes.
                  bloc.add(SelectFriend(friend: friend));
                  Navigator.pop(listenerContext);
                }
                // pinFlowError is shown reactively via the BlocBuilder below
              },
              child: StatefulBuilder(
                builder: (dialogContext, setDialogState) {
                  return AlertDialog(
                    scrollable: true,
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
                              previous.pinFlowError != current.pinFlowError ||
                              previous.pinAttemptsRemaining !=
                                  current.pinAttemptsRemaining ||
                              previous.pinLockedUntil !=
                                  current.pinLockedUntil,
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
                                errorText: _pinErrorText(context, state),
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
                      BlocBuilder<PlayerCustomizationBloc,
                          PlayerCustomizationState>(
                        buildWhen: (previous, current) =>
                            previous.isPinValidating != current.isPinValidating,
                        builder: (context, state) {
                          return TextButton(
                            onPressed: state.isPinValidating
                                ? null
                                : () => Navigator.pop(dialogContext),
                            child: Text(
                              l10n.cancelTextButton,
                              style:
                                  const TextStyle(color: AppColors.neutral60),
                            ),
                          );
                        },
                      ),
                      BlocBuilder<PlayerCustomizationBloc,
                          PlayerCustomizationState>(
                        buildWhen: (previous, current) =>
                            previous.pinFlowError != current.pinFlowError ||
                            previous.isPinValidating != current.isPinValidating,
                        builder: (context, state) {
                          final isLockedOut =
                              state.pinFlowError == PinFlowError.lockedOut;
                          final canSubmit = pinController.text.length == 4 &&
                              !isLockedOut &&
                              !state.isPinValidating;
                          return FilledButton(
                            onPressed: canSubmit
                                ? () {
                                    bloc.add(
                                      ValidatePin(
                                        pin: pinController.text,
                                        friendUserId: friend.userId,
                                      ),
                                    );
                                  }
                                : null,
                            child: state.isPinValidating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(l10n.verifyButtonText),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ).then((_) {
        final confirmed =
            bloc.state.selectedFriend?.userId == friend.userId &&
                bloc.state.pinValidated;
        if (!confirmed) {
          _forceReset();
        }
      }),
    );
  }
}
