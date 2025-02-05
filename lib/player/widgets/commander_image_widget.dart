import 'package:flutter/material.dart';

class CommanderImageWidget extends StatelessWidget {
  const CommanderImageWidget({
    required this.imageUrl,
    required this.playerColor,
    this.partnerImageUrl,
    super.key,
  });

  final String imageUrl;
  final String? partnerImageUrl;
  final int playerColor;

  @override
  Widget build(BuildContext context) {
    const size = 300.0;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
        child: partnerImageUrl == null
            ? _CommanderImage(
                imageUrl: imageUrl,
                playerColor: playerColor,
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _CommanderImage(
                      imageUrl: imageUrl,
                      playerColor: playerColor,
                    ),
                  ),
                  Expanded(
                    child: _CommanderImage(
                      imageUrl: partnerImageUrl!,
                      playerColor: playerColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CommanderImage extends StatelessWidget {
  const _CommanderImage({
    required this.imageUrl,
    required this.playerColor,
  });

  final String imageUrl;
  final int playerColor;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        decoration: BoxDecoration(
          color: Color(playerColor).withAlpha(128),
          borderRadius: const BorderRadius.all(
            Radius.circular(20),
          ),
        ),
      ),
    );
  }
}
