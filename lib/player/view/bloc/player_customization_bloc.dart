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
    on<UpdateCommanderFilters>(_onUpdateCommanderFilters);
    on<UpdatePartnerSelection>(_onUpdatePartnerSelection);
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

      final filteredCards = cardList.data
          .where((card) => card.typeLine.toLowerCase().contains('legendary'))
          .toList();
      emit(
        state.copyWith(
          status: PlayerCustomizationStatus.success,
          cardList: cardList,
          filteredCards: filteredCards,
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
        status: PlayerCustomizationStatus.success,
        commander: event.commander,
        partner: event.partner,
      ),
    );
  }

  void _onUpdateAccountOwnership(
    UpdateAccountOwnership event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWith(isAccountOwner: event.isOwner));
  }

  void _onUpdateCommanderFilters(
    UpdateCommanderFilters event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    final cardList = event.showOnlyLegendary
        ? state.cardList?.data
            .where((card) => card.typeLine.toLowerCase().contains('legendary'))
            .toList()
        : state.cardList?.data ?? [];

    emit(
      state.copyWith(
          showOnlyLegendary: event.showOnlyLegendary,
          hasPartner: event.hasPartner,
          filteredCards: cardList),
    );
  }

  void _onUpdatePartnerSelection(
    UpdatePartnerSelection event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(
      state.copyWith(
        selectingPartner: event.selectingPartner,
      ),
    );
  }
}
