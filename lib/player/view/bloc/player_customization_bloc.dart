import 'package:api_client/api_client.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

part 'player_customization_event.dart';
part 'player_customization_state.dart';

class PlayerCustomizationBloc
    extends Bloc<PlayerCustomizationEvent, PlayerCustomizationState> {
  PlayerCustomizationBloc({required ScryfallRepository scryfallRepository})
      : _scryfallRepository = scryfallRepository,
        super(const PlayerCustomizationState()) {
    on<CardListRequested>(_cardListRequested);
    on<UpdatePlayerCommander>(updatePlayerCommander);
    on<UpdateAccountOwnership>(_onUpdateAccountOwnership);
  }

  final ScryfallRepository _scryfallRepository;

  Future<void> _cardListRequested(
    CardListRequested event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PlayerCustomizationStatus.loading,
      ),
    );
    try {
      final cardList = await _scryfallRepository.getCardFullText(
        cardName: event.cardName,
      );
      emit(
        state.copyWith(
          status: PlayerCustomizationStatus.success,
          cardList: cardList,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PlayerCustomizationStatus.failure,
        ),
      );
    }
  }

  Future<void> updatePlayerCommander(
    UpdatePlayerCommander event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PlayerCustomizationStatus.loading,
      ),
    );

    emit(
      state.copyWith(
        status: PlayerCustomizationStatus.success,
        commander: event.commander,
      ),
    );
  }

  void _onUpdateAccountOwnership(
    UpdateAccountOwnership event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWith(isAccountOwner: event.isOwner));
  }
}
