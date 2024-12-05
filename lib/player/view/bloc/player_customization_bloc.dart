import 'package:api_client/api_client.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

part 'player_customization_event.dart';
part 'player_customization_state.dart';

class PlayerCustomizationBloc
    extends Bloc<PlayerCustomizationEvent, PlayerCustomizationState> {
  PlayerCustomizationBloc({required ScryfallRepository scryfallRepository})
      : _scryfallRepository = scryfallRepository,
        super(const PlayerCustomizationState()) {
    on<CardListRequested>(_cardListRequested);
    on<UpdatePlayerName>(updatePlayerName);
    on<UpdatePlayerPicture>(updatePlayerPicture);
  }

  final ScryfallRepository _scryfallRepository;

  Future<void> _cardListRequested(
    CardListRequested event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    emit(
      const PlayerCustomizationState(
        status: PlayerCustomizationStatus.loading,
      ),
    );
    try {
      final cardList = await _scryfallRepository.getCardFullText(
        cardName: event.cardName,
      );
      emit(
        PlayerCustomizationState(
          status: PlayerCustomizationStatus.success,
          cardList: cardList,
        ),
      );
    } catch (e) {
      emit(
        const PlayerCustomizationState(
          status: PlayerCustomizationStatus.failure,
        ),
      );
    }
  }

  Future<void> updatePlayerName(
    UpdatePlayerName event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    emit(
      const PlayerCustomizationState(
        status: PlayerCustomizationStatus.loading,
      ),
    );

    emit(
      PlayerCustomizationState(
        status: PlayerCustomizationStatus.success,
        name: event.name,
      ),
    );
  }

  Future<void> updatePlayerPicture(
    UpdatePlayerPicture event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    emit(
      const PlayerCustomizationState(
        status: PlayerCustomizationStatus.loading,
      ),
    );

    emit(
      PlayerCustomizationState(
        status: PlayerCustomizationStatus.success,
        imageURL: event.imageUrl,
      ),
    );
  }
}
