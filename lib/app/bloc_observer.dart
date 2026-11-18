import 'dart:developer';

import 'package:analytics_repository/analytics_repository.dart';
import 'package:bloc/bloc.dart';

class AppBlocObserver extends BlocObserver {
  AppBlocObserver({
    AnalyticsRepository? analyticsRepository,
  }) : _analyticsRepository = analyticsRepository;

  final AnalyticsRepository? _analyticsRepository;

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    log('onError ${bloc.runtimeType}', error: error, stackTrace: stackTrace);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    final dynamic state = change.nextState;

    log('onChange ${bloc.runtimeType}, state: ${state.toString().limit(200)}');
    if (state is AnalyticsEventMixin) _analyticsRepository?.track(state.event);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);

    log('onEvent ${bloc.runtimeType}, event: ${event.toString().limit(200)}');

    if (event is AnalyticsEventMixin) _analyticsRepository?.track(event.event);
  }
}

extension on String {
  String limit(int length) {
    return length < this.length ? '${substring(0, length)}...' : this;
  }
}
