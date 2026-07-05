import 'package:app_ui/app_ui.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';
import 'package:magic_yeti/friends_list/search_user/bloc/search_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';

class SearchUserPage extends StatelessWidget {
  const SearchUserPage({super.key});

  factory SearchUserPage.pageBuilder(_, __) {
    return const SearchUserPage(key: Key('search_user_page'));
  }

  static const routeName = 'searchUser';
  static const routePath = '/searchUser';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.quaternary,
        title: Text(
          context.l10n.findFriendsTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.onSurfaceVariant,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocProvider(
        create: (context) => SearchBloc(
          repository: context.read<FirebaseDatabaseRepository>(),
        ),
        child: const SearchUserForm(),
      ),
    );
  }
}

class SearchUserForm extends StatefulWidget {
  const SearchUserForm({super.key});

  @override
  SearchUserFormState createState() => SearchUserFormState();
}

class SearchUserFormState extends State<SearchUserForm> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // The search-by-friend-code callable rejects anonymous callers outright;
    // show intentional copy instead of a confusing error after they search.
    final isAnonymous =
        context.watch<AppBloc>().state.status == AppStatus.anonymous;
    if (isAnonymous) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.signInToSearchFriends,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final currentUserId = context.read<AppBloc>().state.user.id;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: context.l10n.friendCodeSearchHint,
              labelStyle: const TextStyle(color: AppColors.neutral60),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neutral60),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.tertiary),
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.neutral60,
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                context.read<SearchBloc>().add(
                      SearchByFriendCode(value, currentUserId),
                    );
              }
            },
          ),
        ),
        Expanded(
          child: BlocConsumer<SearchBloc, SearchState>(
            listener: (context, state) {
              if (state is FriendRequestSent) {
                final message = switch (state.result) {
                  FriendRequestResult.sent =>
                    context.l10n.friendRequestSentMessage,
                  FriendRequestResult.autoAccepted => 'You are now friends!',
                  FriendRequestResult.alreadyFriends => 'Already friends',
                  FriendRequestResult.alreadyPending =>
                    'Request already pending',
                  FriendRequestResult.self => 'Cannot add yourself',
                };
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor:
                        state.result == FriendRequestResult.sent ||
                                state.result == FriendRequestResult.autoAccepted
                            ? AppColors.green
                            : AppColors.neutral60,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is SearchLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is FriendRequestSent) {
                if (state.users.isEmpty) {
                  return const SizedBox.shrink();
                }
                final status = switch (state.result) {
                  FriendRequestResult.sent => RelationshipStatus.pendingSent,
                  FriendRequestResult.autoAccepted =>
                    RelationshipStatus.friends,
                  FriendRequestResult.alreadyFriends =>
                    RelationshipStatus.friends,
                  FriendRequestResult.alreadyPending =>
                    RelationshipStatus.pendingSent,
                  FriendRequestResult.self => RelationshipStatus.self,
                };
                return _SearchResultCard(
                  user: state.users.first,
                  status: status,
                );
              } else if (state is SearchLoaded) {
                if (state.users.isEmpty) {
                  return Center(
                    child: Text(
                      context.l10n.noUserFoundMessage,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return _SearchResultCard(
                  user: state.users.first,
                  status: state.relationshipStatus,
                );
              } else if (state is SearchError) {
                return Center(
                  child: Text(
                    'Error: ${state.message}',
                    style: const TextStyle(
                      color: AppColors.red,
                    ),
                  ),
                );
              } else {
                return Center(
                  child: Text(
                    context.l10n.friendCodeSearchPrompt,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.user,
    required this.status,
  });

  final UserProfileModel user;
  final RelationshipStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.tertiary,
              child: Text(
                (user.username ?? '?').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username ?? 'Unknown',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    user.friendCode ?? '',
                    style: const TextStyle(
                      color: AppColors.neutral60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _buildTrailing(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    switch (status) {
      case RelationshipStatus.none:
        return FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.background,
          ),
          onPressed: () {
            final appBloc = context.read<AppBloc>();
            context.read<SearchBloc>().add(
                  AddFriendRequest(
                    appBloc.state.user.id,
                    appBloc.state.user.name ?? '',
                    user.id,
                  ),
                );
          },
          child: Text(context.l10n.addFriendButtonText),
        );
      case RelationshipStatus.pendingSent:
        return const Text(
          'Pending',
          style: TextStyle(
            color: AppColors.neutral60,
            fontStyle: FontStyle.italic,
          ),
        );
      case RelationshipStatus.pendingReceived:
        return FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.background,
          ),
          onPressed: () {
            final appBloc = context.read<AppBloc>();
            context.read<SearchBloc>().add(
                  AddFriendRequest(
                    appBloc.state.user.id,
                    appBloc.state.user.name ?? '',
                    user.id,
                  ),
                );
          },
          child: const Text('Accept'),
        );
      case RelationshipStatus.friends:
        return const Text(
          '✓ Friends',
          style: TextStyle(color: AppColors.green),
        );
      case RelationshipStatus.self:
        return const Text(
          'This is you',
          style: TextStyle(
            color: AppColors.neutral60,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }
}
