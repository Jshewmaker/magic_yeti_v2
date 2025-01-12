import 'package:flutter/material.dart';

class CommanderImageWidget extends StatelessWidget {
  const CommanderImageWidget({
    required this.imageUrl,
    required this.playerColor,
    super.key,
  });

  final String imageUrl;
  final int playerColor;

  @override
  Widget build(BuildContext context) {
    const size = 300.0;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              color: Color(playerColor).withValues(alpha: .8),
              borderRadius: const BorderRadius.all(
                Radius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
