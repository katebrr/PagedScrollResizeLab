import SwiftUI

struct KeyValueRow: View {
  private let key: String
  private let value: String
  private let detail: String?
  private let emphasized: Bool

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
