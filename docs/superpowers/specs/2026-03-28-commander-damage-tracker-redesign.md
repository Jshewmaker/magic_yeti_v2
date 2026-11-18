# Commander Damage Tracker Redesign

## Overview

Two changes to the commander damage tracker based on real user testing feedback:

1. **Partner commanders display side-by-side** instead of vertically stacked, fitting naturally in the horizontal scroll list.
2. **Tap-anywhere to increment** with long-press to reveal a decrement zone, replacing the current left/right split interaction.

## Change 1: Partner Tile Layout

### Problem

The commander damage tracker is a horizontal scrolling list at the bottom of the screen. When a player has partner commanders, the current implementation stacks them vertically in a `Column`, making the partner tile group twice as tall as single-commander tiles. This looks wrong in a horizontal scroller and wastes vertical space.

### Solution

Place partner commander tiles **side-by-side in a horizontal `Row`**, wrapped in a shared container using the target player's color as background.

### Behavior

- **Non-partner commanders**: Render as a single square tile (unchanged from today).
- **Partner commanders**: Render as two square tiles in a `Row`, each the same size as a non-partner tile. The `Row` is wrapped in a container with:
  - Background color: target player's color (semi-transparent)
  - Rounded corners (10px)
  - Small padding (8px) around both tiles
  - Small gap (4px) between tiles
- Each tile independently tracks its own `DamageType` (`commander` or `partner`).
- Commander tile appears first (left), partner tile second (right).

### Files Changed

- `lib/tracker/commander_damage_tracker_widget.dart` — In `CommanderDamageTracker.build()`, change the `hasPartner` branch from a `Column` to a `Row`. The container styling remains the same, just the axis changes.

### Data Model

No changes. The existing `DamageType.commander` / `DamageType.partner` enum, `CommanderDamage` model, and `Opponent.damages` list all work as-is.

## Change 2: Tap-to-Increment / Long-Press-to-Decrement

### Problem

The current interaction splits each tile into left (decrement) and right (increment) halves. Users reported that decrementing is rare, and the split makes the increment target area smaller than it needs to be. Users accidentally decrement when trying to increment.

### Solution

Make the entire tile an increment target. Use long-press to expand the tile and reveal a large decrement zone.

### Behavior

**Normal state (tile not expanded):**
- Tap anywhere on the tile = increment (+1 commander damage, -1 life)
- Long-press = expand the tile (existing 200ms animation to `expandedTileSize`, which is 1.4x)

**Expanded state (after long-press):**
- Top half of tile: tap to increment. Shows "+" icon.
- Bottom half of tile: tap to decrement. Shows "−" icon with a semi-transparent dark overlay to visually distinguish it from the top half.
- The decrement zone covers ~50% of the expanded tile height — a large, easy tap target.
- Tap outside the expanded tile = collapse back to normal state (existing `TapRegion` behavior).

### Interaction Detail

| State | Gesture | Action |
|-------|---------|--------|
| Normal | Tap | Increment |
| Normal | Long-press | Expand tile |
| Expanded | Tap top half | Increment |
| Expanded | Tap bottom half | Decrement |
| Expanded | Tap outside | Collapse |

### Files Changed

- `lib/tracker/commander_damage_tracker_widget.dart`:
  - **`CommanderDamageButton`**: Remove `_isRightHalf()` method. Change `onTap` to always call `_increment()`. Keep `_tapDownPosition` for expanded-state vertical hit detection.
  - **Expanded state gesture handling**: When expanded, both `onTap` and `onLongPressDown` use `_isTopHalf()` (new method, checks `localPosition.dy` against `box.size.height / 2`) instead of `_isRightHalf()`. Top half = increment, bottom half = decrement.
  - **`_CommanderIcons`**: Replace the current horizontal `Row` with `−` on left and `+` on right with a vertical `Column` layout: `+` icon in top half, `−` icon with semi-transparent background overlay covering the bottom half.

### What Gets Removed

- `_isRightHalf()` method
- The horizontal left/right icon layout in `_CommanderIcons`
- The `_tapDownPosition` check in normal (non-expanded) `onTap` — normal tap always increments

## Scope

These changes are isolated to `lib/tracker/commander_damage_tracker_widget.dart`. No data model changes, no bloc changes, no changes to other widgets. The `TrackerWidgets` container, `PlayerBloc` events, and `CommanderDamage` model all remain unchanged.

## Testing

- Verify partner tiles render side-by-side in the horizontal scroll list
- Verify non-partner tiles are unaffected
- Verify tap-anywhere increments damage in normal state
- Verify long-press expands tile
- Verify top-half tap increments in expanded state
- Verify bottom-half tap decrements in expanded state
- Verify tap-outside collapses expanded tile
- Verify life points update correctly with both increment and decrement
