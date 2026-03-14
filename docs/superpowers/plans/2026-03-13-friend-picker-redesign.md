# Friend Picker Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the ad-hoc friend chip picker with a dedicated, vertically scrolling friend section that has proper profile pictures, PIN-verified selection with retry, and a read-only linked name field.

**Architecture:** UI-only rework of `_FriendSelectionSection` → `_FriendSection` in `customize_player_page.dart`, plus a one-line bloc fix and a linked badge on `PlayerNameRow`. No new files, blocs, events, or state fields.

**Tech Stack:** Flutter, BLoC, existing `FriendBloc`, `PlayerCustomizationBloc`

**Spec:** `docs/superpowers/specs/2026-03-13-friend-picker-redesign.md`

---

## Chunk 1: Bloc Fix & PlayerNameRow Update

### Task 1: Fix `_onSelectFriend` to preserve `pinValidated`

**Files:**
- Modify: `lib/player/view/bloc/player_customization_bloc.dart:129-139`

- [ ] **Step 1: Change `pinValidated: false` to `pinValidated: true` in `_onSelectFriend`**

In `lib/player/view/bloc/player_customization_bloc.dart`, find the `_onSelectFriend` method (lines 129-139) and change line 136:

```dart
  void _onSelectFriend(
    SelectFriend event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(
      state.copyWith(
        selectedFriend: event.friend,
        pinValidated: true,  // Changed from false — SelectFriend is now only dispatched after successful PIN validation
        pinError: '',
      ),
    );
  }
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/player/view/bloc/player_customization_bloc.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/player/view/bloc/player_customization_bloc.dart
git commit -m "fix: _onSelectFriend preserves pinValidated for dispatch-after-validation flow"
```

---

### Task 2: Add `isLinkedToFriend` parameter to `PlayerNameRow`

**Files:**
- Modify: `lib/player/view/widgets/player_name_row.dart`

- [ ] **Step 1: Add the parameter and update the prefix icon**

In `lib/player/view/widgets/player_name_row.dart`, add `isLinkedToFriend` parameter to the constructor and update the `prefixIcon`:

```dart
class PlayerNameRow extends StatelessWidget {
  const PlayerNameRow({
    required this.textController,
    required this.showOnlyLegendary,
    required this.hasPartner,
    this.focusNode,
    this.isReadOnly = false,
    this.isLinkedToFriend = false,
    super.key,
  });

  final TextEditingController textController;
  final FocusNode? focusNode;
  final bool showOnlyLegendary;
  final bool hasPartner;
  final bool isReadOnly;
  final bool isLinkedToFriend;
```

Then update the `prefixIcon` in the `InputDecoration` (line 40-41) from:

```dart
                prefixIcon:
                    const Icon(Icons.edit, color: AppColors.neutral60),
```

to:

```dart
                prefixIcon: Icon(
                  isLinkedToFriend ? Icons.link : Icons.edit,
                  color: isLinkedToFriend
                      ? AppColors.green
                      : AppColors.neutral60,
                ),
```

- [ ] **Step 2: Update the call site in `customize_player_page.dart`**

In `lib/player/view/customize_player_page.dart`, find the `PlayerNameRow` usage (lines 178-185) and add `isLinkedToFriend`:

```dart
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
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/player/view/widgets/player_name_row.dart lib/player/view/customize_player_page.dart`

- [ ] **Step 4: Commit**

```bash
git add lib/player/view/widgets/player_name_row.dart lib/player/view/customize_player_page.dart
git commit -m "feat: add isLinkedToFriend parameter to PlayerNameRow for linked badge"
```

---

## Chunk 2: Replace Friend Section UI

### Task 3: Replace `_FriendSelectionSection` with `_FriendSection`

**Files:**
- Modify: `lib/player/view/customize_player_page.dart:172-176` (call site) and `225-371` (widget definition)

- [ ] **Step 1: Update the call site in the `CustomScrollView` slivers**

In `lib/player/view/customize_player_page.dart`, replace the `_FriendSelectionSection` sliver (lines 172-176) with:

```dart
                      SliverToBoxAdapter(
                        child: _FriendSection(
                          nameController: _nameController,
                        ),
                      ),
```

- [ ] **Step 2: Delete `_FriendSelectionSection` and replace with `_FriendSection`**

Delete the entire `_FriendSelectionSection` class (lines 225-371) and replace with the following:

```dart
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
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final friend = friends[index];
                final isSelected = isLinked &&
                    customState.selectedFriend?.userId == friend.userId;
                return _FriendTile(
                  friend: friend,
                  isSelected: isSelected,
                  onTap: () => _showPinDialog(context, friend),
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
                        style: const TextStyle(color: AppColors.neutral60),
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
                                borderSide:
                                    BorderSide(color: AppColors.neutral60),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.tertiary),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.red),
                              ),
                              focusedErrorBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.red),
                              ),
                              errorText: state.pinError.isNotEmpty
                                  ? state.pinError
                                  : null,
                              errorStyle:
                                  const TextStyle(color: AppColors.red),
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
                        style: const TextStyle(color: AppColors.neutral60),
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
    ).then((_) => pinController.dispose());
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.tertiary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Profile picture or first-letter fallback
            friend.profilePictureUrl.isNotEmpty
                ? CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.tertiary,
                    backgroundImage:
                        NetworkImage(friend.profilePictureUrl),
                  )
                : CircleAvatar(
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
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/player/view/customize_player_page.dart`

- [ ] **Step 4: Run full analysis to catch regressions**

Run: `flutter analyze`

Fix any new warnings introduced by the changes. Pre-existing warnings can be ignored.

- [ ] **Step 5: Commit**

```bash
git add lib/player/view/customize_player_page.dart
git commit -m "feat: redesign friend picker with vertical list, profile pictures, and PIN retry"
```
