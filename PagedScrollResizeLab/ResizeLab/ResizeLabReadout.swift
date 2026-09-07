import SwiftUI

struct ResizeLabReadout: View {
  private enum Constants {
    /// Fixed log height so appending writes never resizes the pager under test.
    static let logHeight: CGFloat = 112
  }

  private let viewModel: ResizeLabViewModel

  init(viewModel: ResizeLabViewModel) {
    self.viewModel = viewModel
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      KeyValueRow("Container width", value: format(viewModel.containerWidth))
      KeyValueRow("Offset x", value: hasScrollMetrics ? format(viewModel.contentOffsetX) : "–")
      KeyValueRow(
        "Offset ÷ width",
        value: hasScrollMetrics ? ratioDescription : "–",
        detail: hasScrollMetrics && !viewModel.isPageAligned ? "MISALIGNED" : nil,
        emphasized: true
      )
      KeyValueRow("Selection", value: viewModel.currentSelection.map(String.init) ?? "nil")
      KeyValueRow("Phase", value: hasScrollMetrics ? viewModel.scrollPhase : "–")
      if viewModel.variant == .fix {
        KeyValueRow("Fix path", value: fixPathDescription)
      }

      writesLog
        .frame(height: Constants.logHeight, alignment: .topLeading)
    }
    .padding(.horizontal, 24)
    .contentShape(Rectangle())
    .onTapGesture { viewModel.clearSelectionWrites() }
  }

  private var writesLog: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("SCROLLPOSITION WRITES (TAP TO CLEAR)")
        .font(.caption2.bold())
        .foregroundStyle(.tertiary)

      if viewModel.selectionWrites.isEmpty {
        Text("none")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      ForEach(viewModel.selectionWrites.reversed()) { write in
        Text("\(timestamp(write.timestamp))  →  \(write.value.map(String.init) ?? "nil")")
          .font(.caption2)
          .foregroundStyle(write.value == nil ? .primary : .secondary)
          .monospacedDigit()
      }
    }
  }

  /// TabView exposes no scroll geometry, so offset-based rows apply only to
  /// the ScrollView variants.
  private var hasScrollMetrics: Bool {
    viewModel.variant != .tabView
  }

  private var ratioDescription: String {
    viewModel.pageRatio.map { String(format: "%.3f", $0) } ?? "–"
  }

  private var fixPathDescription: String {
    if #available(iOS 27.0, *) {
      "active (iOS 27+)"
    } else {
      "NO-OP — fix needs iOS 27"
    }
  }

  private func format(_ value: CGFloat) -> String {
    String(format: "%.1f", value)
  }

  private func timestamp(_ date: Date) -> String {
    date.formatted(.dateTime.hour().minute().second().secondFraction(.fractional(2)))
  }
}
