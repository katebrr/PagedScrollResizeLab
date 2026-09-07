# Feedback Assistant report (draft)

**Title:** SwiftUI: paged ScrollView (.scrollTargetBehavior(.paging) + .scrollPosition(id:)) loses page alignment when the window is resized on iOS 27

**Area:** SwiftUI / iPadOS windowing

---

## Description

We build BeReal. Several of our production screens are horizontal pagers built on SwiftUI paged ScrollViews — a memories timeline pager, a reactions pager, a recap slideshow, and the home feed tab switcher — all using the standard recipe:

```swift
ScrollView(.horizontal) {
  HStack(spacing: 0) {
    ForEach(pages) { page in
      PageView(page)
        .containerRelativeFrame(.horizontal)
    }
  }
  .scrollTargetLayout()
}
.scrollTargetBehavior(.paging)
.scrollPosition(id: $selection)
```

On iOS 27, when the app window is resized (resizable windows on iPad), the scroll view preserves its content offset **in points**, not in pages. Because the page width just changed, the pager ends up resting between pages or on a different page. During the resize, the `scrollPosition(id:)` binding is written with `nil` while the offset is indeterminate, so the selection cannot be restored from the binding alone. Both `.paging` and `.viewAligned` snap behaviors are affected.

`TabView` with `.tabViewStyle(.page)` survives the same resize correctly, but it is not a viable replacement for these pagers (see below).

A sample project reproducing the issue, with live scroll instrumentation and five isolated variants (minimal repro, binding-shim control, production shape, TabView control, and our workaround), is available here: **<REPO_URL>**

## Steps to reproduce

1. Run the attached sample (`PagedScrollResizeLab`) on an iPad simulator or device with iOS 27.
2. Open "Paged Resize Lab", variant "A · Minimal".
3. Swipe to page 2.
4. Resize the window.

## Expected

The pager still shows page 2, edge-aligned — the same behavior TabView(.page) (variant D) exhibits.

## Actual

The readout in the sample shows the content offset staying constant in points while the container width changes; offset ÷ width becomes non-integer ("MISALIGNED") and the pager rests between pages. The `scrollPosition` write log shows the binding being set to `nil` during the resize.

## Why we can't adopt TabView(.page) instead

Our pagers depend on paged-ScrollView capabilities that TabView(.page) does not offer (each demonstrated in the sample's "Why not TabView" screen):

1. Drag-tracked per-page parallax via `.scrollTransition(.interactive)`.
2. Peeking carousels — pages narrower than the container centered with `.contentMargins` (TabView pages are always container-sized).
3. Inter-page spacing visible during the swipe.
4. Conditionally suspending the paging swipe with `.scrollDisabled(_:)` while a child gesture (media zoom, pull-to-dismiss) owns the touch.
5. Continuous scroll progress via `onScrollGeometryChange`, driving animated tab indicators.
6. Fixed chrome above the pager via `.overlay(alignment: .top)` (e.g. a gradient scrim ignoring the safe area) — inside TabView this conflicts with the container's safe-area handling. We previously had to replace a TabView-based pager with a UIKit UIScrollView wrapper because of safe-area issues.

## Current workaround

We apply a custom modifier to every paged ScrollView (full source in the sample repo, `View+ScrollPositionResize.swift`): it observes the container length via `onGeometryChange`, tracks user scrolling via `onScrollPhaseChange` so it never fights a live gesture, remembers the last non-nil selection (since the binding reports `nil` mid-resize), then — one `Task.yield()` after the resize layout pass — restores the page with `ScrollViewProxy.scrollTo(target, anchor:)` inside a `disablesAnimations` transaction.

Caveats: the restore lands one frame behind the resize (transient misalignment during a live window drag); it snaps to the nearest page rather than proportionally preserving the offset; and it relies on observed behaviors (nil binding writes mid-resize, scrollTo-vs-layout timing) rather than documented contracts.

## Questions

1. Is the current resize behavior of paged ScrollViews intended, or a bug?
2. Is there a supported way to anchor a paged ScrollView to its current page across container resizes — an existing API we're missing, or a planned one?
3. If a manual restore is currently the right approach, do you have a better recommendation than our ScrollViewReader/`scrollTo`-after-`Task.yield()` formulation?
