import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'life_change_event.dart';
part 'life_change_state.dart';

class LifeChangeBloc extends Bloc<LifeChangeEvent, LifeChangeState> {
  LifeChangeBloc() : super(const LifeChangeState()) {
    on<LifePointsChanged>(_onLifePointsChanged);
    on<LifePointChangeCompleted>(_onLifePointChangeCompleted);
  }

  void _onLifePointsChanged(
    LifePointsChanged event,
    Emitter<LifeChangeState> emit,
  ) {
    // If this is the first time or life points have changed

    final newChange = event.newLifePoints - (event.previousLifePoints);

    // Accumulate or set the new change
    final totalChange =
        state.change != null ? state.change! + newChange : newChange;

    emit(state.copyWith(change: totalChange));
  }

  void _onLifePointChangeCompleted(
    LifePointChangeCompleted event,
    Emitter<LifeChangeState> emit,
  ) {
    // Reset the change when animation is complete
    emit(const LifeChangeState());
  }
}
