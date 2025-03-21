import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/timer/bloc/timer_bloc.dart';

/// A widget that automatically resumes the timer when user interactions are detected.
/// 
/// Wrap this around any widget that should trigger timer resumption on interaction.
/// This eliminates the need to add timer resumption logic to every onPressed callback.
class AutoResumeTimerWrapper extends StatelessWidget {
  /// Creates an AutoResumeTimerWrapper.
  ///
  /// The [child] parameter is required and represents the widget that will be
  /// wrapped with the auto-resume functionality.
  ///
  /// The [enabled] parameter determines whether the auto-resume functionality
  /// is active. Defaults to true.
  const AutoResumeTimerWrapper({
    required this.child,
    this.enabled = true,
    super.key,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// Whether the auto-resume functionality is enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // If disabled, just return the child directly
    if (!enabled) return child;

    return Listener(
      // Using Listener instead of GestureDetector to capture all interactions
      // without interfering with child widget's gesture handling
      onPointerDown: (_) => _resumeTimerIfPaused(context),
      behavior: HitTestBehavior.translucent, // Allow hit testing to pass through
      child: child,
    );
  }

  void _resumeTimerIfPaused(BuildContext context) {
    try {
      // Try to access the TimerBloc
      final timerBloc = context.read<TimerBloc>();
      
      // Only resume if the timer is currently paused
      if (timerBloc.state.status == TimerStatus.paused) {
        timerBloc.add(const TimerResumeEvent());
      }
    } catch (e) {
      // TimerBloc might not be available in the widget tree
      // Just ignore and continue
    }
  }
}
