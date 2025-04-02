import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/friends_list/search_user/bloc/search_bloc.dart';

/// This file implements the user search functionality for the friends list feature.
/// It allows users to search for other users by username or email.
///
/// Key features:
/// - Search input for username or email
/// - Display search results with user details
/// - Handle empty search results and errors
///
/// @dependencies
/// - Firebase Firestore: Used for querying user data
/// - Flutter Bloc: Used for managing state
///
/// @notes
/// - Ensures real-time search updates using Firestore
/// - Implements error handling for network issues and invalid inputs
class SearchUserPage extends StatelessWidget {
  const SearchUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search by username or email',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                BlocProvider.of<SearchBloc>(context).add(SearchUsers(value));
              }
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is SearchLoaded) {
                return ListView.builder(
                  itemCount: state.users.length,
                  itemBuilder: (context, index) {
                    final user = state.users[index];
                    return ListTile(
                      title: Text(user.username ?? ''),
                      subtitle: Text(user.email ?? ''),
                    );
                  },
                );
              } else if (state is SearchError) {
                return Center(child: Text('Error: ${state.message}'));
              } else {
                return const Center(child: Text('No results found.'));
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
