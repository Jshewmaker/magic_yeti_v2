import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/life_counter/life_counter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  factory HomePage.pageBuilder(_, __) {
    return const HomePage(
      key: Key('home_page'),
    );
  }

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                context.read<GameBloc>().add(
                      const CreateGameEvent(
                        numberOfPlayers: 2,
                        startingLifePoints: 20,
                      ),
                    );
                context.go(GamePage.routePath);
              },
              child: Text(l10n.numberOfPlayers(2)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<GameBloc>().add(
                      const CreateGameEvent(
                        numberOfPlayers: 4,
                        startingLifePoints: 40,
                      ),
                    );
                context.go(GamePage.routePath);
              },
              child: Text(l10n.numberOfPlayers(4)),
            ),
          ],
        ),
      ),
    );
  }
}
