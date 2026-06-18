// test/match_details/widgets/commander_picker_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/match_details/bloc/commander_picker_cubit.dart';
import 'package:magic_yeti/match_details/widgets/commander_picker.dart';
import 'package:player_repository/player_repository.dart';

import '../../helpers/card_fixtures.dart';
import '../../helpers/helpers.dart';

class _MockCommanderPickerCubit extends MockCubit<CommanderPickerState>
    implements CommanderPickerCubit {}

void main() {
  late CommanderPickerCubit cubit;

  setUp(() => cubit = _MockCommanderPickerCubit());

  testWidgets('tapping a result card pops with the mapped commander',
      (tester) async {
    final card = buildMagicCard(id: 'card-id', name: 'Atraxa');
    whenListen(
      cubit,
      const Stream<CommanderPickerState>.empty(),
      initialState: CommanderPickerState(
        status: CommanderPickerStatus.success,
        cards: [card],
      ),
    );

    Commander? result;
    await tester.pumpApp(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await Navigator.of(context).push<Commander>(
              MaterialPageRoute<Commander>(
                builder: (_) => BlocProvider<CommanderPickerCubit>.value(
                  value: cubit,
                  child: const CommanderPickerView(selectingPartner: false),
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('commander-card-card-id')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'Atraxa');
  });
}
