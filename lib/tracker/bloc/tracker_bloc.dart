import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'tracker_event.dart';
part 'tracker_state.dart';

class TrackerBloc extends Bloc<TrackerEvent, TrackerState> {
  TrackerBloc() : super(const TrackerState()) {
    on<AddTrackerIcon>(_onAddTrackerIcon);
    on<RemoveTrackerIcon>(_onRemoveTrackerIcon);
    on<ResetTrackerIcons>(_onResetTrackerIcons);
  }

  void _onAddTrackerIcon(AddTrackerIcon event, Emitter<TrackerState> emit) {
    if (!state.icons.contains(event.icon)) {
      emit(state.copyWith(icons: [...state.icons, event.icon]));
    }
  }

  void _onRemoveTrackerIcon(
      RemoveTrackerIcon event, Emitter<TrackerState> emit) {
    final updatedIcons = List<IconData>.from(state.icons)..remove(event.icon);
    emit(state.copyWith(icons: updatedIcons));
  }

  void _onResetTrackerIcons(
      ResetTrackerIcons event, Emitter<TrackerState> emit) {
    emit(const TrackerState());
  }
}
