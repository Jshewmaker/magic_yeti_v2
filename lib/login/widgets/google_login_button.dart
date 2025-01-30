import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton(
      {required this.buttonText, required this.onPressed, super.key});

  final String buttonText;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FontAwesomeIcons.google, color: AppColors.white),
          const SizedBox(width: AppSpacing.xlg),
          Text(buttonText),
        ],
      ),
    );
  }
}
