part of 'player_customization_bloc.dart';

enum PlayerCustomizationStatus { initial, loading, success, failure }

class PlayerCustomizationState extends Equatable {
  const PlayerCustomizationState({
    this.status = PlayerCustomizationStatus.initial,
    this.name = '',
    this.commander,
    this.partner,
    this.background,
    this.cardList,
    this.magicCardList,
    this.isAccountOwner = false,
    this.showOnlyLegendary = true,
    this.availablePairing = CommanderPairing.none,
    this.selectingSecondCard = false,
    this.recents = const [],
    this.favorites = const [],
    this.favoriteIds = const {},
    this.selectedFriend,
    this.pinValidated = false,
    this.pinError = '',
  });

  final PlayerCustomizationStatus status;
  final String name;
  final Commander? commander;
  final Commander? partner;
  final Commander? background;
  final SearchCards? cardList;
  final List<MagicCard>? magicCardList;
  final bool isAccountOwner;
  final bool showOnlyLegendary;
  final CommanderPairing availablePairing;
  final bool selectingSecondCard;
  final List<Commander> recents;
  final List<Commander> favorites;
  final Set<String> favoriteIds;
  final FriendModel? selectedFriend;
  final bool pinValidated;
  final String pinError;

  /// Commander-damage clocks this player will be tracked with: the commander,
  /// plus the partner if present. A background never adds a clock.
  int get damageClocks => 1 + (partner != null ? 1 : 0);

  /// Combined color identity across commander, partner and background, ordered
  /// W, U, B, R, G.
  List<String> get colorIdentity {
    final set = <String>{};
    for (final c in [commander, partner, background]) {
      set.addAll(c?.colorIdentity ?? c?.colors ?? const []);
    }
    const order = ['W', 'U', 'B', 'R', 'G'];
    return order.where(set.contains).toList();
  }

  @override
  List<Object?> get props => [
        status,
        name,
        commander,
        partner,
        background,
        cardList,
        magicCardList,
        isAccountOwner,
        showOnlyLegendary,
        availablePairing,
        selectingSecondCard,
        recents,
        favorites,
        favoriteIds,
        selectedFriend,
        pinValidated,
        pinError,
      ];

  PlayerCustomizationState copyWith({
    PlayerCustomizationStatus? status,
    String? name,
    Commander? Function()? commander,
    Commander? Function()? partner,
    Commander? Function()? background,
    SearchCards? cardList,
    List<MagicCard>? filteredCards,
    bool? isAccountOwner,
    bool? showOnlyLegendary,
    CommanderPairing? availablePairing,
    bool? selectingSecondCard,
    List<Commander>? recents,
    List<Commander>? favorites,
    Set<String>? favoriteIds,
    FriendModel? selectedFriend,
    bool? pinValidated,
    String? pinError,
  }) {
    return PlayerCustomizationState(
      status: status ?? this.status,
      name: name ?? this.name,
      commander: commander != null ? commander() : this.commander,
      partner: partner != null ? partner() : this.partner,
      background: background != null ? background() : this.background,
      cardList: cardList ?? this.cardList,
      magicCardList: filteredCards ?? magicCardList,
      isAccountOwner: isAccountOwner ?? this.isAccountOwner,
      showOnlyLegendary: showOnlyLegendary ?? this.showOnlyLegendary,
      availablePairing: availablePairing ?? this.availablePairing,
      selectingSecondCard: selectingSecondCard ?? this.selectingSecondCard,
      recents: recents ?? this.recents,
      favorites: favorites ?? this.favorites,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      selectedFriend: selectedFriend ?? this.selectedFriend,
      pinValidated: pinValidated ?? this.pinValidated,
      pinError: pinError ?? this.pinError,
    );
  }

  PlayerCustomizationState copyWithClearedFriend() {
    return PlayerCustomizationState(
      status: status,
      name: name,
      commander: commander,
      partner: partner,
      background: background,
      cardList: cardList,
      magicCardList: magicCardList,
      isAccountOwner: isAccountOwner,
      showOnlyLegendary: showOnlyLegendary,
      availablePairing: availablePairing,
      selectingSecondCard: selectingSecondCard,
      recents: recents,
      favorites: favorites,
      favoriteIds: favoriteIds,
    );
  }
}
