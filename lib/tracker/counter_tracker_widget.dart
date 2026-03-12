import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/app/utils/device_info_provider.dart';
import 'package:magic_yeti/tracker/counter_bloc/counter_bloc.dart';
import 'package:magic_yeti/tracker/tracker_sizes.dart';

class CounterTrackerWidget extends StatelessWidget {
  const CounterTrackerWidget({
    required this.icon,
    super.key,
  });
  final Icon icon;
  @override
  Widget build(BuildContext context) {
    final sizes = TrackerSizes.fromDevice(
      isPhone: DeviceInfoProvider.of(context).isPhone,
    );
    return BlocProvider(
      create: (context) => CounterBloc(),
      child: BlocBuilder<CounterBloc, CounterState>(
        builder: (context, state) {
          return GestureDetector(
            onTap: () =>
                context.read<CounterBloc>().add(CounterIncrementPressed()),
            onLongPress: () =>
                context.read<CounterBloc>().add(CounterDecrementPressed()),
            onLongPressUp: () =>
                context.read<CounterBloc>().add(CounterStopDecrementing()),
            child: Container(
              height: sizes.tileSize,
              width: sizes.tileSize,
              padding: const EdgeInsets.only(top: 10),
              color: AppColors.neutral60.withValues(alpha: .2),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  icon,
                  StrokeText(
                    text: state.counter.toString(),
                    fontSize: sizes.textSize,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
