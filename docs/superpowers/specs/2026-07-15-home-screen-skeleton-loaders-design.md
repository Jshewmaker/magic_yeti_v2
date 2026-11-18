# Home Screen Skeleton Loaders — Design

**Date:** 2026-07-15
**Status:** Approved

## Problem

The home screen's data-driven widgets already show loading indication, but only as
plain centered `CircularProgressIndicator` spinners. They feel cheap and don't
communicate the shape of the content that's about to appear. We want polished
skeleton (shimmer) placeholders that match each widget's layout.

Existing spinners being replaced:

- `MatchHistoryPanel` — `Center(CircularProgressIndicator)` for
  `initial` / `loadingHistory` states (`lib/home/home_page.dart`).
- `StatsOverviewWidget` — dropdown + `CircularProgressIndicator` for the
  `StatsOverviewLoading` state (`lib/stats_overview/widgets/stats_overview.dart`).
- `AccountWidget` — bare `CircularProgressIndicator` while a logged-in user's
  match history is still loading, before `StatsOverviewWidget` renders
  (`lib/home/home_page.dart`).

Both the phone and tablet views reuse `MatchHistoryPanel` and `AccountWidget`, so
both layouts are covered by the same changes.

## Approach

Use the `shimmer` package with **hand-built** skeleton layouts (chosen over the
`skeletonizer` package and a fully custom shimmer, to balance control against
effort).

Standard performant shimmer pattern: a single `Shimmer.fromColors(...)` wraps a
whole skeleton layout composed of plain grey "bone" containers, so one
synchronized sweep animates across the entire area rather than one animation per
box.

### Dependency

- Add `shimmer: ^3.0.0` to `packages/app_ui/pubspec.yaml` (the UI kit — where
  shared widgets live).

### New reusable primitives in `app_ui`

1. `AppShimmer` — wraps any child in `Shimmer.fromColors` using two new themed
   colors tuned for the dark palette:
   - `AppColors.skeletonBase` ≈ `#2E313F`
   - `AppColors.skeletonHighlight` ≈ `#3D4152`
2. `SkeletonBone` — a grey rounded `Container` primitive (`width`, `height`,
   `borderRadius`) that reads its color from the shimmer base. The building block
   for all skeleton layouts.

Both exported from `package:app_ui/app_ui.dart`.

### Hand-built skeleton layouts (home feature, `lib/home/widgets/`)

1. `MatchHistorySkeleton` — a non-scrolling list of ~5 bone cards shaped like
   `CustomListItem` (height 160: a winner thumbnail block + a losers block + a
   column of stacked text-line bones). Wrapped in one `AppShimmer`.
2. `StatsOverviewSkeleton` — keeps the **real** dropdown (so there's no layout
   jump between loading and loaded), then a `GridView.count(crossAxisCount: 3)`
   of ~9 bone stat tiles matching `StatsWidget` (a `50×80` stat bone + a title
   bone). Grid content wrapped in one `AppShimmer`.

### Avatar placeholder

The profile avatar in `SectionHeader` (`lib/home/home_page.dart`) loads a network
image (`CircleAvatar(backgroundImage: NetworkImage(...))`) with no placeholder.
Add a shimmer circle placeholder while the image loads, so it's consistent with
the rest of the screen.

### Wiring

| Location | Today | After |
|---|---|---|
| `MatchHistoryPanel` initial/loadingHistory | `Center(CircularProgressIndicator)` | `MatchHistorySkeleton` |
| `StatsOverviewWidget` `StatsOverviewLoading` | dropdown + spinner | dropdown + `StatsOverviewSkeleton` grid |
| `AccountWidget` loading branch | bare `CircularProgressIndicator` | `StatsOverviewSkeleton` |
| `SectionHeader` avatar | `NetworkImage` (no placeholder) | shimmer circle while loading |

## Out of scope

- `GameModeButtons` — static content, no data to load.
- Any change to the loading *logic* / bloc states — this is purely swapping the
  visual placeholder. The same states that show a spinner today show a skeleton
  after.

## Testing

- Widget test: `MatchHistoryPanel` renders `MatchHistorySkeleton` (and no
  `CircularProgressIndicator`) when the `MatchHistoryBloc` is in
  `initial` / `loadingHistory`.
- Widget test: `StatsOverviewWidget` renders `StatsOverviewSkeleton` for
  `StatsOverviewLoading`.
- Widget test: `AppShimmer` / `SkeletonBone` render without error (smoke test in
  `app_ui`).
- Verify `flutter analyze` is clean and existing home/stats tests still pass.
