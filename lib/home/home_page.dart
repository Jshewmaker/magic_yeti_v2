import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app_router/routes.dart';
import 'package:magic_yeti/game/bloc/game_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                context
                    .read<GameBloc>()
                    .add(const CreateGameEvent(numberOfPlayers: 4));
                context.go(
                  const LifeCounterRoute().path,
                );
              },
              child: const Text('4 Player'),
            ),
          ],
        ),
      ),
    );
  }
}
