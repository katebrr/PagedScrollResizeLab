import SwiftUI

// MARK: - Preserves Scroll Position

public extension View {
  /// Restores a paged scroll view to `selection` after its container is resized.
  ///
  /// iOS 27 and later only; earlier versions are left untouched.
  ///
  /// - Parameters:
  ///   - selection: The page to keep in place. Pass the same value bound to `scrollPosition(id:)`.
  ///   - anchor: Where the page settles. `center` for container-width pages, `leading` for narrower ones.
  ///   - axis: The scroll axis whose container length is observed.
  @ViewBuilder
  func preservesScrollPosition<ID: Hashable & Sendable>(
    of selection: ID?,
    anchor: UnitPoint = .center,
    axis: Axis = .horizontal
  ) -> some View {
    if #available(iOS 27.0, *) {
      modifier(ScrollPositionResizeModifier(selection: selection, anchor: anchor, axis: axis))
    } else {
      self
    }
  }
}

// MARK: - ScrollPositionResizeModifier

@available(iOS 27.0, *)
private struct ScrollPositionResizeModifier<ID: Hashable & Sendable>: ViewModifier {
  let selection: ID?
  let anchor: UnitPoint
  let axis: Axis

  @State private var containerLength: CGFloat = 0
  @State private var pendingResize = 0
  @State private var restoredResize = 0
  /// `scrollPosition(id:)` reports nil while the offset is indeterminate mid-resize.
  @State private var lastKnownSelection: ID?
  @State private var isUserScrolling = false

  func body(content: Content) -> some View {
    ScrollViewReader { proxy in
      content
        .onGeometryChange(for: CGFloat.self) { geometry in
          axis == .horizontal ? geometry.size.width : geometry.size.height
        } action: { newLength in
          guard newLength > 0, newLength != containerLength else { return }
          let isFirstMeasurement = containerLength == 0
          containerLength = newLength
          // Initial layout: scrollPosition(id:) places that one itself.
          guard !isFirstMeasurement else { return }
          pendingResize += 1
        }
        .onScrollPhaseChange { _, newPhase, _ in
          isUserScrolling = switch newPhase {
          case .tracking, .interacting, .decelerating: true
          // .animating is this modifier's own restore.
          case .idle, .animating: false
          @unknown default: false
          }
        }
        .task(id: RestoreKey(resize: pendingResize, isUserScrolling: isUserScrolling)) {
          await restoreIfNeeded(using: proxy)
        }
        .onChange(of: selection) { _, newValue in
          if let newValue { lastKnownSelection = newValue }
        }
        .onAppear {
          if let selection { lastKnownSelection = selection }
        }
    }
  }

  // MARK: - Restore

  private func restoreIfNeeded(using proxy: ScrollViewProxy) async {
    guard pendingResize > restoredResize else { return }
    // Not consumed: the phase change re-keys this task, so the restore lands on gesture end.
    guard !isUserScrolling else { return }
    guard let target = selection ?? lastKnownSelection else {
      restoredResize = pendingResize
      return
    }

    // scrollTo resolves against committed geometry, one turn behind the resize layout pass.
    await Task.yield()
    guard !Task.isCancelled, !isUserScrolling else { return }

    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      proxy.scrollTo(target, anchor: anchor)
    }
    restoredResize = pendingResize
  }
}

// MARK: - RestoreKey

private struct RestoreKey: Equatable {
  let resize: Int
  let isUserScrolling: Bool
}
