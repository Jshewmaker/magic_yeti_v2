class TrackerSizes {
  const TrackerSizes._({
    required this.tileSize,
    required this.expandedTileSize,
    required this.panelHeight,
    required this.iconSize,
    required this.textSize,
    required this.buttonIconSize,
  });

  factory TrackerSizes.fromDevice({required bool isPhone}) {
    final base = isPhone ? 100.0 : 140.0;
    return TrackerSizes._(
      tileSize: base,
      expandedTileSize: base * 1.4,
      panelHeight: base + 16,
      iconSize: base * 0.45,
      textSize: base * 0.28,
      buttonIconSize: base * 0.25,
    );
  }

  final double tileSize;
  final double expandedTileSize;
  final double panelHeight;
  final double iconSize;
  final double textSize;
  final double buttonIconSize;
}
