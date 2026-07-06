import 'package:api_client/api_client.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database_repository/firebase_database_repository.dart';
import 'package:magic_yeti/commander_library/commander_library_repository.dart';
import 'package:player_repository/player_repository.dart';
import 'package:scryfall_repository/scryfall_repository.dart';

part 'player_customization_event.dart';
part 'player_customization_state.dart';

class PlayerCustomizationBloc
    extends Bloc<PlayerCustomizationEvent, PlayerCustomizationState> {
  PlayerCustomizationBloc({
    required ScryfallRepository scryfallRepository,
    required FirebaseDatabaseRepository firebaseDatabaseRepository,
    required CommanderLibraryRepository commanderLibraryRepository,
  })  : _scryfallRepository = scryfallRepository,
        _firebaseDatabaseRepository = firebaseDatabaseRepository,
        _library = commanderLibraryRepository,
        super(const PlayerCustomizationState()) {
    on<LibraryRequested>(_onLibraryRequested);
    on<CardListRequested>(_cardListRequested);
    on<CommanderSelected>(_onCommanderSelected);
    on<SecondCardSelected>(_onSecondCardSelected);
    on<StartSelectingSecondCard>(_onStartSelectingSecondCard);
    on<CancelSelectingSecondCard>(_onCancelSelectingSecondCard);
    on<SecondCardCleared>(_onSecondCardCleared);
    on<CommanderFavoriteToggled>(_onFavoriteToggled);
    on<UpdateAccountOwnership>(_onUpdateAccountOwnership);
    on<UpdateCommanderFilters>(_onUpdateCommanderFilters);
    on<ClearCardList>(_onClearCardList);
    on<SelectFriend>(_onSelectFriend);
    on<OwnerSelected>(_onOwnerSelected);
    on<LinkCleared>(_onLinkCleared);
    on<ValidatePin>(_onValidatePin);
    on<ResetPinFlow>(_onResetPinFlow);
  }

  final ScryfallRepository _scryfallRepository;
  final FirebaseDatabaseRepository _firebaseDatabaseRepository;
  final CommanderLibraryRepository _library;

  String _id(Commander c) => c.oracleId ?? c.name;

  Future<void> _onLibraryRequested(
    LibraryRequested event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    final recents = await _library.getRecents();
    final favorites = await _library.getFavorites();
    emit(
      state.copyWith(
        recents: recents,
        favorites: favorites,
        favoriteIds: favorites.map(_id).toSet(),
      ),
    );
  }

  Future<void> _cardListRequested(
    CardListRequested event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    emit(state.copyWith(status: PlayerCustomizationStatus.loading));
    try {
      final cardList = await _scryfallRepository.getCardFullText(
        cardName: event.cardName,
      );
      final filteredCards = cardList.data.where((card) {
        final type = card.typeLine?.toLowerCase() ?? '';
        if (event.searchBackgrounds) return type.contains('background');
        return type.contains('legendary');
      }).toList();
      emit(
        state.copyWith(
          status: PlayerCustomizationStatus.success,
          cardList: cardList,
          filteredCards: filteredCards,
        ),
      );
    } on Exception catch (_) {
      emit(state.copyWith(status: PlayerCustomizationStatus.failure));
    }
  }

  Future<void> _onCommanderSelected(
    CommanderSelected event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    await _library.addRecent(event.commander);
    final recents = await _library.getRecents();
    emit(
      state.copyWith(
        status: PlayerCustomizationStatus.success,
        commander: () => event.commander,
        partner: () => null,
        background: () => null,
        availablePairing: commanderPairingFor(event.commander),
        selectingSecondCard: false,
        recents: recents,
      ),
    );
  }

  Future<void> _onSecondCardSelected(
    SecondCardSelected event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    await _library.addRecent(event.card);
    final recents = await _library.getRecents();
    final isBackground = state.availablePairing == CommanderPairing.background;
    emit(
      state.copyWith(
        status: PlayerCustomizationStatus.success,
        partner: () => isBackground ? state.partner : event.card,
        background: () => isBackground ? event.card : state.background,
        selectingSecondCard: false,
        recents: recents,
      ),
    );
  }

  void _onStartSelectingSecondCard(
    StartSelectingSecondCard event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(
      state.copyWith(
        selectingSecondCard: true,
        filteredCards: [],
      ),
    );
  }

  void _onCancelSelectingSecondCard(
    CancelSelectingSecondCard event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWith(selectingSecondCard: false));
  }

  void _onSecondCardCleared(
    SecondCardCleared event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(
      state.copyWith(
        partner: () => null,
        background: () => null,
        selectingSecondCard: false,
      ),
    );
  }

  Future<void> _onFavoriteToggled(
    CommanderFavoriteToggled event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    await _library.toggleFavorite(event.commander);
    final favorites = await _library.getFavorites();
    emit(
      state.copyWith(
        favorites: favorites,
        favoriteIds: favorites.map(_id).toSet(),
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
    final cards = event.showOnlyLegendary
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
        filteredCards: cards,
      ),
    );
  }

  void _onSelectFriend(
    SelectFriend event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWithFriendSelected(event.friend));
  }

  Future<void> _onOwnerSelected(
    OwnerSelected event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    emit(state.copyWithOwnerSelected());
    try {
      final profile =
          await _firebaseDatabaseRepository.getUserProfileOnce(event.userId);
      if (profile?.username != null && profile!.username!.isNotEmpty) {
        emit(state.copyWith(ownerUsername: profile.username));
      }
    } on Exception catch (_) {
      // Leave ownerUsername unset — PlayerIdentityPanel falls back to
      // whatever name was already persisted for this seat. isAccountOwner
      // stays confirmed either way; a failed username fetch shouldn't
      // block linking the seat to the owner's account.
    }
  }

  void _onLinkCleared(
    LinkCleared event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(state.copyWithLinkCleared());
  }

  Future<void> _onValidatePin(
    ValidatePin event,
    Emitter<PlayerCustomizationState> emit,
  ) async {
    emit(state.copyWith(isPinValidating: true));
    final result = await _firebaseDatabaseRepository.validatePin(
      targetUserId: event.friendUserId,
      pin: event.pin,
    );
    switch (result) {
      case PinValid():
        emit(
          state.copyWith(
            isPinValidating: false,
            pinValidated: true,
            pinFlowError: PinFlowError.none,
            pinLockedUntil: () => null,
          ),
        );
      case PinInvalid(:final attemptsRemaining):
        emit(
          state.copyWith(
            isPinValidating: false,
            pinValidated: false,
            pinFlowError: PinFlowError.incorrect,
            pinAttemptsRemaining: attemptsRemaining,
            pinLockedUntil: () => null,
          ),
        );
      case PinLockedOut(:final lockedUntil):
        emit(
          state.copyWith(
            isPinValidating: false,
            pinValidated: false,
            pinFlowError: PinFlowError.lockedOut,
            pinLockedUntil: () => lockedUntil,
          ),
        );
      case PinNotSet():
        emit(
          state.copyWith(
            isPinValidating: false,
            pinValidated: false,
            pinFlowError: PinFlowError.notSet,
            pinLockedUntil: () => null,
          ),
        );
      case PinCheckUnavailable():
        emit(
          state.copyWith(
            isPinValidating: false,
            pinValidated: false,
            pinFlowError: PinFlowError.unavailable,
            pinLockedUntil: () => null,
          ),
        );
    }
  }

  void _onResetPinFlow(
    ResetPinFlow event,
    Emitter<PlayerCustomizationState> emit,
  ) {
    emit(
      state.copyWith(
        pinFlowError: PinFlowError.none,
        pinAttemptsRemaining: 0,
        pinLockedUntil: () => null,
      ),
    );
  }
}
