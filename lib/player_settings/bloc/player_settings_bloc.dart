import 'package:api_client/api_client.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

part 'player_settings_event.dart';
part 'player_settings_state.dart';

class ScryfallBloc extends Bloc<PlayerSettingsEvent, PlayerSettingsState> {
  ScryfallBloc({required ScryfallRepository scryfallRepository})
      : _scryfallRepository = scryfallRepository,
        super(PlayerSettingsInitial()) {
    on<PlayerSettingsCardRequested>(_cardListRequested);
  }
  final ScryfallRepository _scryfallRepository;
  Future<void> _cardListRequested(
    PlayerSettingsCardRequested event,
    Emitter<PlayerSettingsState> emit,
  ) async {
    emit(PlayerSettingsLoading());
    try {
      final cardList = await _scryfallRepository.getCardFullText(
        cardName: event.cardName,
      );
      emit(PlayerSettingsLoadSuccess(cardList));
    } catch (e) {
      emit(PlayerSettingsLoadFailure());
    }
  }
}
