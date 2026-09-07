import Foundation
import Observation

/// Kept outside view `@State` so per-frame scroll callbacks don't rebuild the pager.
@MainActor
@Observable
final class ResizeLabMetrics {
  struct SelectionWrite: Identifiable {
    let id = UUID()
    let value: Int?
    let timestamp: Date
  }

  var containerWidth: CGFloat = 0
  var contentOffsetX: CGFloat = 0
  var scrollPhase = "n/a"
  private(set) var selectionWrites: [SelectionWrite] = []

  var pageRatio: Double? {
    guard containerWidth > 0 else { return nil }
    return contentOffsetX / containerWidth
  }

  var isPageAligned: Bool {
    guard let pageRatio else { return true }
    return abs(pageRatio - pageRatio.rounded()) < 0.01
  }

  func recordSelectionWrite(_ value: Int?) {
    selectionWrites.append(SelectionWrite(value: value, timestamp: .now))
    if selectionWrites.count > 6 {
      selectionWrites.removeFirst(selectionWrites.count - 6)
    }
  }

  func reset() {
    selectionWrites.removeAll()
  }
}
