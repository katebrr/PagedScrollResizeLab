import Foundation
import Observation

/// Lab state and scroll instrumentation, kept out of view `@State` so
/// per-frame scroll callbacks don't rebuild the pager.
@MainActor
@Observable
final class ResizeLabViewModel {
  struct SelectionWrite: Identifiable {
    let id = UUID()
    let value: Int?
    let timestamp: Date
  }

  private enum Constants {
    static let pageCount = 5
    /// Readout log length; older writes scroll off.
    static let maxLoggedWrites = 6
  }

  let pageCount = Constants.pageCount

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

  /// Logs every write; `nil` (emitted mid-resize and on teardown) is logged
  /// but never clears the selection.
  func select(_ value: Int?) {
    selectionWrites.append(SelectionWrite(value: value, timestamp: .now))
    if selectionWrites.count > Constants.maxLoggedWrites {
      selectionWrites.removeFirst(selectionWrites.count - Constants.maxLoggedWrites)
    }
    guard let value else { return }
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
