import Foundation
import Observation

/// Lab state and scroll instrumentation.
///
/// Kept outside view `@State` so per-frame scroll callbacks only invalidate
/// the views that read them, not the pager itself.
@MainActor
@Observable
final class ResizeLabViewModel {
  struct SelectionWrite: Identifiable {
    let id = UUID()
    let value: Int?
    let timestamp: Date
  }

  let pageCount = 5

  var variant: LabVariant = .scrollView
  private(set) var selection: Int? = 0
  private(set) var containerWidth: CGFloat = 0
  private(set) var contentOffsetX: CGFloat = 0
  private(set) var scrollPhase = "n/a"
  private(set) var selectionWrites: [SelectionWrite] = []

  var pageRatio: Double? {
    guard containerWidth > 0 else { return nil }
    return contentOffsetX / containerWidth
  }

  var isPageAligned: Bool {
    guard let pageRatio else { return true }
    return abs(pageRatio - pageRatio.rounded()) < 0.01
  }

  /// Records every write, including the `nil` ones emitted mid-resize.
  func select(_ value: Int?) {
    selectionWrites.append(SelectionWrite(value: value, timestamp: .now))
    if selectionWrites.count > 6 {
      selectionWrites.removeFirst(selectionWrites.count - 6)
    }
    selection = value
  }

  func updateContainerWidth(_ width: CGFloat) {
    containerWidth = width
  }

  func updateContentOffset(_ offsetX: CGFloat) {
    contentOffsetX = offsetX
  }

  func updateScrollPhase(_ phase: String) {
    scrollPhase = phase
  }

  func clearSelectionWrites() {
    selectionWrites.removeAll()
  }
}
