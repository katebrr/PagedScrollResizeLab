# Paged ScrollView vs window resize (iOS 27)

Minimal sample app demonstrating that a **paged SwiftUI `ScrollView`** (`HStack` + `.scrollTargetBehavior(.paging)` + `.scrollPosition(id:)`) **loses page alignment when its container is resized** — e.g. when the user resizes the app window on iPad — while `TabView(.page)` survives the same resize, and why `TabView` is nonetheless not a viable replacement for real-world pagers.

This repo accompanies a Feedback Assistant report (see [FEEDBACK.md](FEEDBACK.md)). We ship BeReal; several of our production screens are horizontal pagers built on paged ScrollViews (a memories timeline pager, a reactions pager, a recap slideshow, the home feed tab switcher).

**Expected:** after a container resize, the pager still shows the page that was selected, edge-aligned.
**Actual:** the content offset is preserved in *points*, not in *pages*. Since the page width just changed, the view lands between pages or on a different page. During the resize, the `scrollPosition(id:)` binding is written with `nil`, so the selection cannot be restored from the binding alone.

## Requirements

- Xcode 26+, iOS 18+ deployment target
- **The bug and the workaround are demonstrated on iOS 27**, where app windows are user-resizable. Run on an iPad simulator or device with iOS 27.

## Reproduction steps

1. Open `PagedScrollResizeLab.xcodeproj`, run on an **iPad simulator (iOS 27)**.
2. Open **Paged Resize Lab**, keep variant **A · Minimal**.
3. Swipe to page 2 or 3.
4. Grab the window handle and resize the window.
5. Watch the readout: **Offset x** stays constant in points while **Container width** changes, so **Offset ÷ width** becomes non-integer and flags **MISALIGNED**. The pager rests between pages.
6. Switch to variant **D · TabView** and repeat: the page is preserved.
7. Switch to variant **E · Fix** and repeat: the page is preserved via our workaround.

The readout also logs every write to the `scrollPosition(id:)` binding — during a resize you can see it being written with `nil` while the offset is indeterminate.

## What each variant proves

| Variant | Setup | On resize |
|---|---|---|
| **A · Minimal** | Bare paged ScrollView, plain `scrollPosition(id:)` binding | ❌ misaligned |
| **B · Nil shim** | Binding shim that swallows the `nil` writes | ❌ misaligned — the stale `nil` is not the root cause, the offset itself is never re-derived from the page |
| **C · Production** | B plus `.animation` and a top overlay (the shape of our production pagers) | ❌ misaligned |
| **D · TabView(.page)** | Same pages inside `TabView` | ✅ survives (UIPageViewController-backed) |
| **E · Fix** | A plus our `preservesScrollPosition(of:)` modifier | ✅ survives |

Both snap behaviors (`.paging` and `.viewAligned`) are affected; the lab lets you toggle between them.

## Why we can't just use TabView(.page)

The **Why not TabView(.page)** screen demonstrates paged-ScrollView features our production pagers rely on, none of which `TabView(.page)` offers:

| # | Need | ScrollView API | TabView(.page) |
|---|---|---|---|
| 1 | Drag-tracked per-page parallax | `.scrollTransition(.interactive)` | No per-page transition phase |
| 2 | Peeking carousel (pages narrower than container, neighbors visible) | `.contentMargins` + `.viewAligned` | Pages are always container-sized |
| 3 | Visible gutter between pages during swipe | `HStack(spacing:)` | No inter-page spacing |
| 4 | Suspend paging while a child gesture owns the touch (zoom, pull-to-dismiss) | `.scrollDisabled(_:)` | Swipe can't be suspended |
| 5 | Continuous scroll progress driving an animated tab indicator | `onScrollGeometryChange` | No progress feed |
| 6 | Fixed chrome above the pager (gradient scrim ignoring safe area) | `.overlay(alignment: .top)` | Fights the container's safe-area handling |

We have direct history here: an earlier TabView-based pager had to be replaced with a hand-rolled `UIScrollView` wrapper because of safe-area issues (#6), and another screen migrated from `TabView` to a paged ScrollView specifically to get the overlay scrim right. TabView remains fine for our simple full-screen media galleries — but not for the pagers above.

## The workaround

[`View+ScrollPositionResize.swift`](PagedScrollResizeLab/Workaround/View+ScrollPositionResize.swift) — a `preservesScrollPosition(of:anchor:axis:)` modifier applied to the paged ScrollView, passing the same value bound to `scrollPosition(id:)`:

1. `onGeometryChange` observes the container length along the scroll axis; any change after the first measurement marks a pending restore.
2. `onScrollPhaseChange` tracks whether the user is actively scrolling, so a restore never fights a live gesture (it re-arms and lands when the gesture ends).
3. The restore `await`s one `Task.yield()` so `scrollTo` resolves against committed geometry (one turn behind the resize layout pass), then calls `ScrollViewProxy.scrollTo(target, anchor:)` inside a transaction with `disablesAnimations = true`.
4. Because `scrollPosition(id:)` reports `nil` mid-resize, the modifier keeps the last non-nil selection and restores to that.

Known caveats we'd love a better answer for:

- The restore is one frame behind the resize, so a live window drag can show transient misalignment until the restore lands.
- It restores to the nearest page boundary rather than proportionally preserving an in-between offset.
- It depends on observed behaviors (`nil` writes mid-resize, `scrollTo` timing relative to layout) rather than documented contracts.

## The ask

Is there a supported way for a paged `ScrollView` to keep its page across a container resize — an anchor/behavior we're missing, or a planned API? And if the workaround is currently the right approach, is there a more robust formulation than `ScrollViewReader.scrollTo` after `Task.yield()`?

## Screen recordings

*(to be added: variant A misaligning on resize, variants D and E surviving)*
