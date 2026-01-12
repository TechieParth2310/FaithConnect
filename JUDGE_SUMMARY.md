# FaithConnect — Judge Summary (Jan 2026)

## What this app delivers

FaithConnect is a calm, modern spiritual community app built with Flutter + Firebase, combining:

- A premium-feeling **Explore feed** (posts + daily inspiration)
- A dedicated **Reels** experience (short video content)
- Messaging, notifications, leader discovery, profiles

The main focus of this polish pass was: **first-impression UX** and **performance stability**, especially eliminating background Reel initialization (a common cause of Android OOM / ExoPlayer crashes).

---

## Key UX improvements

### Explore (“Home Feed”) polish

- **Non-realtime, paginated Explore feed**: reduces UI jitter and prevents unnecessary Firestore listeners.
- **Icon-first actions**: like/comment/share are icon-centric (counts appear only when relevant).
- **Calm visual hierarchy**: hero card → quick actions → feed cards, with spacing and quiet backgrounds.
- **Skeleton loading + empty state**: avoids “blank screen” feel and improves perceived performance.

### Quick actions strip

A compact horizontal strip using tooltips and icons (no noisy labels) to keep the interface uncluttered while still discoverable.

---

## Performance + memory stability work

### Reels no longer initializes offscreen

**Problem:** bottom-nav implementations that use `IndexedStack` create all tabs immediately. In apps with video playback, that often means `ReelsScreen.initState()` runs even when the user is on Explore, initializing video controllers and Firestore streams in the background.

**Fix:** `MainWrapper` now uses a **lazy-mount strategy**:

- Screens are only built after they have been visited.
- Reels is only created when the Reels tab is tapped.
- Existing “active/inactive” signaling to Reels remains supported.

This directly reduces background memory pressure and is one of the highest-impact fixes for OOM/ExoPlayer stability.

### Lightweight rendering safety

- Posts are wrapped in `RepaintBoundary` in the feed to reduce expensive repaints.
- Cached images use constrained memory cache dimensions (`memCacheWidth/Height`) to reduce bitmap memory spikes.

---

## Firebase / Firestore strategy

### Explore feed strategy

- Prefer one-shot fetch via `get()` with server+cache, with `limit` and `startAfterDocument` pagination.
- Avoid long-lived listeners (`snapshots()`) for Explore to reduce battery/network usage and UI churn.

### Following feed strategy

- Following uses a stream (`snapshots()`) today for realtime behavior.
- Notes:
  - Firestore `whereIn` has a 10-item limit; if scaling beyond that, consider:
    - fan-out writes (denormalized feed)
    - Cloud Functions feed materialization
    - or paging by leader groups

---

## Verification (quality gates)

- `flutter analyze`: **PASS**
- `flutter test`: **PASS**

---

## Where to look in the code

- Navigation + lazy mounting: `faith_connect/lib/screens/main_wrapper.dart`
- Explore feed + pagination: `faith_connect/lib/screens/home_screen.dart`
- Explore pagination API: `faith_connect/lib/services/post_service.dart`
- Premium feed card: `faith_connect/lib/widgets/post_card.dart`
- Hero inspiration card: `faith_connect/lib/widgets/daily_quote_card.dart`

---

## Next optional upgrades (if more time)

- Migrate the Following tab to also support pagination (hybrid realtime: first page realtime, older pages one-shot).
- Replace deprecated Share API usage in older files with `SharePlus.instance.share()`.
- Clean up remaining deprecation warnings project-wide by migrating `withOpacity` → `withValues` where supported.
