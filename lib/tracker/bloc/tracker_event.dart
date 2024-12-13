part of 'tracker_bloc.dart';

abstract class TrackerEvent extends Equatable {
  const TrackerEvent();

  @override
  List<Object?> get props => [];
}

class AddTrackerIcon extends TrackerEvent {
  const AddTrackerIcon(this.icon);

  final IconData icon;

  @override
  List<Object?> get props => [icon];
}

class RemoveTrackerIcon extends TrackerEvent {
  const RemoveTrackerIcon(this.icon);

  final IconData icon;

  @override
  List<Object?> get props => [icon];
}

class ResetTrackerIcons extends TrackerEvent {
  const ResetTrackerIcons();
}
