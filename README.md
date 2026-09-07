# Paged ScrollView vs window resize (iOS 27)

A paged SwiftUI `ScrollView` (`.scrollTargetBehavior(.paging)` + `.scrollPosition(id:)`) loses page alignment when its container is resized — e.g. when the app window is resized on iPad. The content offset is preserved in points, not in pages, and the `scrollPosition(id:)` binding is written `nil` during the resize.

`TabView(.page)` survives the same resize, but is not a viable replacement for feature-rich pagers (see [FEEDBACK.md](FEEDBACK.md)).

## Reproduce

Requires an iPad simulator or device on **iOS 27** (resizable windows).

1. Run the app, keep the **ScrollView** variant.
2. Swipe to page 2.
3. Resize the window.

The readout shows **Offset x** staying constant while **Container width** changes; **Offset ÷ width** becomes non-integer and flags **MISALIGNED**. The write log shows `scrollPosition` being set to `nil` mid-resize.

Repeat with **TabView** (page preserved) and **ScrollView + fix** (page preserved via the workaround).

## Variants

| Variant | On resize |
|---|---|
| **ScrollView** — the standard paging recipe | ❌ lands between pages |
| **TabView(.page)** — same pages | ✅ page preserved |
| **ScrollView + fix** — with `preservesScrollPosition(of:)` | ✅ page preserved |

`.viewAligned` snapping is affected the same way as `.paging`.

## The workaround

[`View+ScrollPositionResize.swift`](PagedScrollResizeLab/Workaround/View+ScrollPositionResize.swift): `onGeometryChange` detects the container resize, `onScrollPhaseChange` defers the restore while the user is scrolling, the last non-nil selection is remembered (the binding reports `nil` mid-resize), then one `Task.yield()` after the resize layout pass the page is restored with `ScrollViewProxy.scrollTo(target, anchor:)` in a `disablesAnimations` transaction.

Caveats: the restore lands one frame behind the resize, and it relies on observed behavior (`nil` binding writes, `scrollTo`-vs-layout timing) rather than documented contracts.
