# Feedback Assistant report — filed as FB24688033

**Title:** SwiftUI: paged ScrollView (.scrollTargetBehavior(.paging) + .scrollPosition(id:)) loses page alignment when resized on iOS 27

**Area:** SwiftUI / iPadOS windowing

---

## Description

Our app (BeReal) uses horizontal pagers built on the standard SwiftUI paging recipe:

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

When the window is resized on iOS 27, the scroll view preserves its content offset in points, not in pages. Because the page width changed, the pager rests between pages or on a different page. During the resize, `scrollPosition(id:)` is written `nil`, so the selection cannot be restored from the binding. Both `.paging` and `.viewAligned` are affected.

Sample project with live instrumentation: **https://github.com/katebrr/PagedScrollResizeLab**

## Steps to reproduce

1. Run the sample on an iPad, iOS 27.
2. In the "ScrollView" variant, swipe to page 2.
3. Resize the window.

**Expected:** page 2 stays edge-aligned, as it does in the sample's `TabView(.page)` variant.

**Actual:** the offset stays constant in points; offset ÷ container width becomes non-integer and the pager rests between pages. The sample's readout logs the `nil` writes to the `scrollPosition` binding during the resize.

## Why not TabView(.page)

`TabView(.page)` handles the resize correctly, but our existing pagers are built around ScrollView APIs that TabView doesn't expose — scroll position and phase observation that our analytics and UI behaviors are plugged into, plus layout and gesture control (page spacing, peeking pages, conditionally disabling the swipe). Moving to TabView would mean losing those integration points, so ScrollView is the base we need to keep.

## Current workaround

`View+ScrollPositionResize.swift` in the sample: detect the container resize via `onGeometryChange`, defer while the user is scrolling (`onScrollPhaseChange`), remember the last non-nil selection, then one `Task.yield()` after the resize restore the page with `ScrollViewProxy.scrollTo(target, anchor:)` in a `disablesAnimations` transaction. It works, but the restore lands one frame behind the resize and relies on observed behavior rather than documented contracts.

## Questions

1. Is this resize behavior of paged ScrollViews intended, or a bug?
2. Is there a supported way to anchor a paged ScrollView to its current page across container resizes?
3. If a manual restore is the right approach today, is there a more robust formulation than `scrollTo` after `Task.yield()`? Our current implementation is in the sample at `PagedScrollResizeLab/Workaround/View+ScrollPositionResize.swift`.
