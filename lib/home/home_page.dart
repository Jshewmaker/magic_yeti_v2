import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:magic_yeti/app_router/app_router.dart';
import 'package:magic_yeti/player/player.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<PlayerBloc>()
                        .add(const CreatePlayerEvent(numberOfPlayers: 4));
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
      },
    );
  }
}
