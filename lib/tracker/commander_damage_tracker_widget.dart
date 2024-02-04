import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/tracker/bloc/tracker_bloc_bloc.dart';

class CommanderDamageTracker extends StatelessWidget {
  const CommanderDamageTracker({
    required this.imageUrl,
    required this.color,
    super.key,
  });
  final String imageUrl;
  final Color color;
  @override
  Widget build(BuildContext context) {
    const width = 60.0;
    const height = 50.0;
    return BlocProvider(
      create: (context) => TrackerBloc(),
      child: BlocBuilder<TrackerBloc, TrackerBlocState>(
        builder: (context, state) {
          return GestureDetector(
            onTap: () =>
                context.read<TrackerBloc>().add(TrackerBlocIncremented()),
            onLongPress: () =>
                context.read<TrackerBloc>().add(TrackerBlocDecremented()),
            onLongPressUp: () =>
                context.read<TrackerBloc>().add(TrackerBlocStopDecrement()),
            child: Container(
              padding: const EdgeInsets.only(top: 10),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Image.network(
                      imageUrl,
                      width: width,
                      height: height,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: color,
                        width: width,
                        height: height,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  StrokeText(
                    text: state.counter.toString(),
                    fontSize: 28,
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
