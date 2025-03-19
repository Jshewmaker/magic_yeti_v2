import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

/// Shows a toast in the top of the screen.
void showToast(BuildContext context, Toast toast) {
  showTopSnackBar(
    Overlay.of(context),
    toast,
  );
}

/// {@template toast}
/// A custom [SnackBar] with an icon and message.
/// {@endtemplate}
class Toast extends StatelessWidget {
  /// {@macro toast}
  const Toast({
    required this.message,
    super.key,
  })  : backgroundColor = AppColors.tertiary,
        icon = const Icon(Icons.info);

  /// A [Toast] styled to show an error message.
  const Toast.error({
    required this.message,
    super.key,
  })  : backgroundColor = AppColors.error,
        icon = const Icon(Icons.error);

  /// A [Toast] styled to show a warning message.
  const Toast.warning({
    required this.message,
    super.key,
  })  : backgroundColor = AppColors.secondary,
        icon = const Icon(Icons.warning);

  /// A [Toast] styled to show a success message.
  const Toast.success({
    required this.message,
    super.key,
  })  : backgroundColor = AppColors.success,
        icon = const Icon(Icons.check_circle);

  /// A [Toast] styled to show an info message.
  const Toast.info({
    required this.message,
    super.key,
  })  : backgroundColor = AppColors.primary,
        icon = const Icon(Icons.info);

  /// The message to be shown.
  final String message;

  /// The background color of the toast.
  final Color backgroundColor;

  /// The leading icon of the toast.
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          color: backgroundColor,
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints.tightFor(
                width: AppSpacing.xlg,
                height: AppSpacing.xlg,
              ),
              child: const Align(
                child: Icon(
                  Icons.close,
                  size: AppSpacing.lg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
