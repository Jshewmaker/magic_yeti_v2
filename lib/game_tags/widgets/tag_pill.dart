import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// The colors of a [TagPill]. The game over screen and the rest of the app
/// use different surfaces, so each passes its own palette.
class TagPillPalette {
  const TagPillPalette({
    required this.accent,
    required this.surface,
    required this.border,
    required this.text,
    required this.mutedText,
  });

  /// The palette for screens on the standard app theme.
  static const app = TagPillPalette(
    accent: AppColors.secondary,
    surface: AppColors.quaternary,
    border: Color(0xFF3D4152),
    text: AppColors.white,
    mutedText: AppColors.neutral60,
  );

  final Color accent;
  final Color surface;
  final Color border;
  final Color text;
  final Color mutedText;
}

/// A rounded tag chip. Tappable when [onTap] is set, read-only otherwise.
class TagPill extends StatelessWidget {
  const TagPill({
    required this.label,
    required this.selected,
    this.onTap,
    this.tooltip,
    this.dense = false,
    this.palette = TagPillPalette.app,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? tooltip;

  /// A small, read-only size for summaries inside a list row.
  final bool dense;

  final TagPillPalette palette;

  @override
  Widget build(BuildContext context) {
    // A dense pill sits on busy backgrounds (commander art), so it gets an
    // opaque fill and light text instead of accent text on a faint tint.
    final foreground = selected && !dense ? palette.accent : palette.text;
    final pill = Material(
      color: switch ((selected, dense)) {
        (true, true) => Color.alphaBlend(
          palette.accent.withValues(alpha: 0.35),
          palette.surface,
        ),
        (true, false) => palette.accent.withValues(alpha: 0.16),
        (false, _) => palette.surface,
      },
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? palette.accent : palette.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: dense
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected && !dense) ...[
                Icon(Icons.check_rounded, size: 14, color: foreground),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: dense ? 11 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final semantic = Semantics(
      button: onTap != null,
      selected: selected,
      child: pill,
    );
    final message = tooltip;
    if (message == null) return semantic;
    return Tooltip(message: message, child: semantic);
  }
}
