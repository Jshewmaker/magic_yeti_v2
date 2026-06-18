part of 'match_edit_cubit.dart';

enum MatchEditStatus { viewing, editing, saving, success, error }

class MatchEditState extends Equatable {
  const MatchEditState({
    this.status = MatchEditStatus.viewing,
    this.draftPlayers = const [],
    this.errorMessage = '',
  });

  final MatchEditStatus status;
  final List<Player> draftPlayers;
  final String errorMessage;

  bool get isEditing =>
      status == MatchEditStatus.editing ||
      status == MatchEditStatus.saving ||
      status == MatchEditStatus.error;

  MatchEditState copyWith({
    MatchEditStatus? status,
    List<Player>? draftPlayers,
    String? errorMessage,
  }) {
    return MatchEditState(
      status: status ?? this.status,
      draftPlayers: draftPlayers ?? this.draftPlayers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, draftPlayers, errorMessage];
}
