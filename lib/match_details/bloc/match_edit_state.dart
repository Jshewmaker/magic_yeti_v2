part of 'match_edit_cubit.dart';

enum MatchEditStatus { viewing, editing, saving, success, error }

class MatchEditState extends Equatable {
  const MatchEditState({
    this.status = MatchEditStatus.viewing,
    this.draftPlayers = const [],
    this.draftGameTags = const [],
    this.errorMessage = '',
  });

  final MatchEditStatus status;
  final List<Player> draftPlayers;

  /// Ids of the game tags while editing. Player tags live on [draftPlayers].
  final List<String> draftGameTags;
  final String errorMessage;

  bool get isEditing =>
      status == MatchEditStatus.editing ||
      status == MatchEditStatus.saving ||
      status == MatchEditStatus.error;

  /// Whether every draft player has a non-blank name.
  bool get canSave =>
      draftPlayers.every((player) => player.name.trim().isNotEmpty);

  MatchEditState copyWith({
    MatchEditStatus? status,
    List<Player>? draftPlayers,
    List<String>? draftGameTags,
    String? errorMessage,
  }) {
    return MatchEditState(
      status: status ?? this.status,
      draftPlayers: draftPlayers ?? this.draftPlayers,
      draftGameTags: draftGameTags ?? this.draftGameTags,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    draftPlayers,
    draftGameTags,
    errorMessage,
  ];
}
