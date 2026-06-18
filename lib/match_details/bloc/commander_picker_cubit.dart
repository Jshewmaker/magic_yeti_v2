import 'package:api_client/api_client.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

part 'commander_picker_state.dart';

class CommanderPickerCubit extends Cubit<CommanderPickerState> {
  CommanderPickerCubit({required ScryfallRepository scryfallRepository})
      : _scryfallRepository = scryfallRepository,
        super(const CommanderPickerState());

  final ScryfallRepository _scryfallRepository;

  Future<void> search(String cardName) async {
    emit(state.copyWith(status: CommanderPickerStatus.loading));
    try {
      final result = await _scryfallRepository.getCardFullText(
        cardName: cardName,
      );
      final legendary = result.data
          .where(
            (card) =>
                card.typeLine?.toLowerCase().contains('legendary') ?? false,
          )
          .toList();
      emit(
        state.copyWith(
          status: CommanderPickerStatus.success,
          cards: legendary,
        ),
      );
    } on Exception catch (_) {
      emit(state.copyWith(status: CommanderPickerStatus.failure));
    }
  }
}
