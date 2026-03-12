import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:player_repository/player_repository.dart';

class CommanderHeroBanner extends StatelessWidget {
  const CommanderHeroBanner({
    required this.playerColor,
    this.commander,
    this.partner,
    super.key,
  });

  final Commander? commander;
  final Commander? partner;
  final int playerColor;

  @override
  Widget build(BuildContext context) {
    final hasCommander = commander?.imageUrl.isNotEmpty ?? false;
    final hasPartner = partner?.imageUrl.isNotEmpty ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(hasCommander, hasPartner),
        _buildGradientOverlay(),
        _buildNameOverlay(context, hasCommander, hasPartner),
      ],
    );
  }

  Widget _buildBackground(bool hasCommander, bool hasPartner) {
    if (!hasCommander) {
      return ColoredBox(
        color: Color(playerColor).withAlpha(80),
        child: const Center(
          child: Icon(Icons.person, size: 64, color: AppColors.neutral60),
        ),
      );
    }

    if (hasPartner) {
      return Row(
        children: [
          Expanded(child: _ArtCropImage(url: commander!.imageUrl)),
          Expanded(child: _ArtCropImage(url: partner!.imageUrl)),
        ],
      );
    }

    return _ArtCropImage(url: commander!.imageUrl);
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 100,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.primary.withAlpha(230),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameOverlay(
    BuildContext context,
    bool hasCommander,
    bool hasPartner,
  ) {
    if (!hasCommander) return const SizedBox.shrink();

    return Positioned(
      bottom: AppSpacing.md,
      left: AppSpacing.xlg,
      right: AppSpacing.xlg,
      child: Row(
        children: [
          Flexible(
            child: Text(
              commander!.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  const Shadow(
                    blurRadius: 4,
                    color: Colors.black54,
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasPartner) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                '&',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: Text(
                partner!.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(
                      blurRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArtCropImage extends StatelessWidget {
  const _ArtCropImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: AppColors.quaternary),
      ),
    );
  }
}
