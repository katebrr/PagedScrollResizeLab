# Paged ScrollView vs window resize (iOS 27)

A paged `ScrollView` (`.scrollTargetBehavior(.paging)` + `.scrollPosition(id:)`) loses page alignment when its container is resized: the content offset is kept in points while the page width changes, and `scrollPosition(id:)` is written `nil` mid-resize. `TabView(.page)` survives the same resize. See [FEEDBACK.md](FEEDBACK.md) for the full report. Filed as **FB24688033**.

## Reproduce

iPad, **iOS 27** (resizable windows):

1. Run the app, **ScrollView** variant.
2. Swipe to page 2.
3. Resize the window → **Offset ÷ width** goes non-integer, flagged **MISALIGNED**; the write log shows `scrollPosition` set to `nil`.

| Variant | On resize |
|---|---|
| ScrollView | ❌ lands between pages |
| TabView(.page) | ✅ page preserved |
| ScrollView + fix | ✅ page preserved |

`.viewAligned` is affected the same way as `.paging`.

## Workaround

[`View+ScrollPositionResize.swift`](PagedScrollResizeLab/Workaround/View+ScrollPositionResize.swift): detect the resize with `onGeometryChange`, wait out user scrolling (`onScrollPhaseChange`), remember the last non-nil selection, then restore it one `Task.yield()` later via `ScrollViewProxy.scrollTo` with animations disabled. Works, but lands one frame late and relies on observed behavior, not documented contracts.
