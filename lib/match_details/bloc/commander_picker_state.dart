part of 'commander_picker_cubit.dart';

enum CommanderPickerStatus { initial, loading, success, failure }

class CommanderPickerState extends Equatable {
  const CommanderPickerState({
    this.status = CommanderPickerStatus.initial,
    this.cards = const [],
  });

  final CommanderPickerStatus status;
  final List<MagicCard> cards;

  CommanderPickerState copyWith({
    CommanderPickerStatus? status,
    List<MagicCard>? cards,
  }) {
    return CommanderPickerState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
    );
  }

  @override
  List<Object?> get props => [status, cards];
}
