import SwiftUI

// MARK: - LabPage

struct LabPage: View {
  let index: Int

  var body: some View {
    ZStack {
      index.isMultiple(of: 2) ? Color(.secondarySystemBackground) : Color(.tertiarySystemBackground)
      VStack(spacing: 8) {
        Text("\(index)")
          .font(.largeTitle.bold())
        Text("page")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

// MARK: - ResizeLabReadout

struct ResizeLabReadout: View {
  let metrics: ResizeLabMetrics
  let selection: Int?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      KeyValueRow("Container width", value: format(metrics.containerWidth))
      KeyValueRow("Offset x", value: format(metrics.contentOffsetX))
      KeyValueRow(
        "Offset ÷ width",
        value: metrics.pageRatio.map { String(format: "%.3f", $0) } ?? "–",
        detail: metrics.isPageAligned ? "aligned" : "MISALIGNED",
        emphasized: !metrics.isPageAligned
      )
      KeyValueRow("Selection", value: selection.map(String.init) ?? "nil")
      KeyValueRow("Phase", value: metrics.scrollPhase)
      KeyValueRow("Fix path", value: fixPathDescription)

      writesLog
    }
    .padding(.horizontal, 24)
    .contentShape(Rectangle())
    .onTapGesture { metrics.reset() }
  }

  private var writesLog: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("SCROLLPOSITION WRITES (TAP TO CLEAR)")
        .font(.caption2.bold())
        .foregroundStyle(.tertiary)

      if metrics.selectionWrites.isEmpty {
        Text("none")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      ForEach(metrics.selectionWrites.reversed()) { write in
        Text("\(timestamp(write.timestamp))  →  \(write.value.map(String.init) ?? "nil")")
          .font(.caption2)
          .foregroundStyle(write.value == nil ? .primary : .secondary)
          .monospacedDigit()
      }
    }
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

// MARK: - KeyValueRow

struct KeyValueRow: View {
  let key: String
  let value: String
  let detail: String?
  let emphasized: Bool

  init(_ key: String, value: String, detail: String? = nil, emphasized: Bool = false) {
    self.key = key
    self.value = value
    self.detail = detail
    self.emphasized = emphasized
  }

  var body: some View {
    HStack(spacing: 8) {
      Text(key)
        .font(.footnote)
        .foregroundStyle(.secondary)
      Spacer()
      if let detail {
        Text(detail)
          .font(.caption2.bold())
          .foregroundStyle(emphasized ? Color.red : Color.secondary)
      }
      Text(value)
        .font(.footnote)
        .monospacedDigit()
    }
  }
}
