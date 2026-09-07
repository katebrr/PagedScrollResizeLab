import SwiftUI

struct LabPage: View {
  private let index: Int

  init(index: Int) {
    self.index = index
  }

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
