part of 'tracker_bloc.dart';

class TrackerState extends Equatable {
  const TrackerState({
    this.icons = const [],
  });

  final List<IconData> icons;

  TrackerState copyWith({
    List<IconData>? icons,
  }) {
    return TrackerState(
      icons: icons ?? this.icons,
    );
  }

  @override
  List<Object> get props => [icons];
}
