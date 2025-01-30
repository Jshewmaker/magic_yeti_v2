import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppleLoginButton extends StatelessWidget {
  const AppleLoginButton(
      {required this.buttonText, required this.onPressed, super.key});

  final String buttonText;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      label: Text(buttonText),
      icon: const Icon(FontAwesomeIcons.apple, color: AppColors.white),
      onPressed: onPressed,
    );
  }
}
