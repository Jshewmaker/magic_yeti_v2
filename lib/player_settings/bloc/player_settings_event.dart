part of 'player_settings_bloc.dart';

sealed class PlayerSettingsEvent extends Equatable {
  const PlayerSettingsEvent();

  @override
  List<Object> get props => [];
}

class PlayerSettingsCardRequested extends PlayerSettingsEvent {
  const PlayerSettingsCardRequested(this.cardName);

  final String cardName;
}
