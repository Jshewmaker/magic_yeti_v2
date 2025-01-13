import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

class PlayerNameInputWidget extends StatelessWidget {
  const PlayerNameInputWidget({
    required this.textController,
    required this.onSavePressed,
    super.key,
  });

  final TextEditingController textController;
  final VoidCallback onSavePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onSubmitted: (value) {
              FocusScope.of(context).unfocus();
            },
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            controller: textController,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ElevatedButton(
          onPressed: onSavePressed,
          style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
