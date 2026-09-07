import Foundation
import Observation

/// Lab state and scroll instrumentation, kept out of view `@State` so
/// per-frame scroll callbacks don't rebuild the pager.
///
/// Each variant owns its own page collection and selection, so a pager being
/// torn down can never write into the state of the pager replacing it.
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

  let scrollViewPages = Array(0..<Constants.pageCount)
  let tabViewPages = Array(0..<Constants.pageCount)
  let fixPages = Array(0..<Constants.pageCount)

  private(set) var variant: LabVariant = .scrollView
  private(set) var scrollViewSelection: Int? = 0
  private(set) var tabViewSelection: Int? = 0
  private(set) var fixSelection: Int? = 0
  private(set) var containerWidth: CGFloat = 0
  private(set) var contentOffsetX: CGFloat = 0
  private(set) var scrollPhase = "n/a"
  private(set) var selectionWrites: [SelectionWrite] = []

  var currentPages: [Int] {
    pages(for: variant)
  }

  var currentSelection: Int? {
    selection(for: variant)
  }

  var pageRatio: Double? {
    guard containerWidth > 0 else { return nil }
    return contentOffsetX / containerWidth
  }

  var isPageAligned: Bool {
    guard let pageRatio else { return true }
    return abs(pageRatio - pageRatio.rounded()) < 0.01
  }

  func pages(for variant: LabVariant) -> [Int] {
    switch variant {
    case .scrollView: scrollViewPages
    case .tabView: tabViewPages
    case .fix: fixPages
    }
  }

  func selection(for variant: LabVariant) -> Int? {
    switch variant {
    case .scrollView: scrollViewSelection
    case .tabView: tabViewSelection
    case .fix: fixSelection
    }
  }

  /// Each variant is an independent demo; entering one starts it at page 0.
  func switchVariant(to newVariant: LabVariant) {
    guard newVariant != variant else { return }
    variant = newVariant
    scrollViewSelection = 0
    tabViewSelection = 0
    fixSelection = 0
    contentOffsetX = 0
    scrollPhase = "n/a"
    selectionWrites.removeAll()
  }

  /// Logs every write; `nil` (emitted mid-resize and on teardown) is logged
  /// but never clears the selection.
  func select(_ value: Int?, in variant: LabVariant) {
    selectionWrites.append(SelectionWrite(value: value, timestamp: .now))
    if selectionWrites.count > Constants.maxLoggedWrites {
      selectionWrites.removeFirst(selectionWrites.count - Constants.maxLoggedWrites)
    }
    guard let value else { return }
    switch variant {
    case .scrollView: scrollViewSelection = value
    case .tabView: tabViewSelection = value
    case .fix: fixSelection = value
    }
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
