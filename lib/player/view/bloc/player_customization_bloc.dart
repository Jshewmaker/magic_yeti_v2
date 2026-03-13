import 'package:api_client/api_client.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

part 'player_customization_event.dart';
part 'player_customization_state.dart';

class PlayerCustomizationBloc
    extends Bloc<PlayerCustomizationEvent, PlayerCustomizationState> {
  PlayerCustomizationBloc({
    required ScryfallRepository scryfallRepository,
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
  })  : _scryfallRepository = scryfallRepository,
        _firebaseDatabaseRepository = firebaseDatabaseRepository,
        super(const PlayerCustomizationState()) {
    on<CardListRequested>(_cardListRequested);
    on<UpdatePlayerCommander>(updatePlayerCommander);
    on<UpdateAccountOwnership>(_onUpdateAccountOwnership);
    on<UpdateCommanderFilters>(_onUpdateCommanderFilters);
    on<UpdatePartnerSelection>(_onUpdatePartnerSelection);
    on<ClearCardList>(_onClearCardList);
    on<SelectFriend>(_onSelectFriend);
    on<ClearFriend>(_onClearFriend);
    on<ValidatePin>(_onValidatePin);
  }

  final ScryfallRepository _scryfallRepository;
  final FirebaseDatabaseRepository _firebaseDatabaseRepository;

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
          .where(
            (card) =>
                card.typeLine?.toLowerCase().contains('legendary') ?? false,
          )
          .toList();
      emit(
        state.copyWith(
          status: PlayerCustomizationStatus.success,
          cardList: cardList,
          filteredCards: filteredCards,
        ),
      );
    } on Exception catch (_) {
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

  void _onClearCardList(
    ClearCardList event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWith(filteredCards: []));
  }

  void _onUpdateCommanderFilters(
    UpdateCommanderFilters event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    final cardList = event.showOnlyLegendary
        ? state.cardList?.data
            .where(
              (card) =>
                  card.typeLine?.toLowerCase().contains('legendary') ?? false,
            )
            .toList()
        : state.cardList?.data ?? [];

    emit(
      state.copyWith(
        showOnlyLegendary: event.showOnlyLegendary,
        hasPartner: event.hasPartner,
        filteredCards: cardList,
      ),
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

  void _onSelectFriend(
    SelectFriend event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(
      state.copyWith(
        selectedFriend: event.friend,
        pinValidated: false,
        pinError: '',
      ),
    );
  }

  void _onClearFriend(
    ClearFriend event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(
      state.copyWithClearedFriend(),
    );
  }

  Future<void> _onValidatePin(
    ValidatePin event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    try {
      final isValid = await _firebaseDatabaseRepository.validatePin(
        event.friendUserId,
        event.pin,
      );
      if (isValid) {
        emit(state.copyWith(pinValidated: true, pinError: ''));
      } else {
        emit(state.copyWith(pinValidated: false, pinError: 'Incorrect PIN'));
      }
    } on Exception catch (_) {
      emit(
        state.copyWith(
          pinValidated: false,
          pinError: 'Failed to validate PIN',
        ),
      );
    }
  }
}
