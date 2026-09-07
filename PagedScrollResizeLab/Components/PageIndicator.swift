import SwiftUI

struct PageIndicator: View {
  private let pageCount: Int
  private let selection: Int?

  init(pageCount: Int, selection: Int?) {
    self.pageCount = pageCount
    self.selection = selection
  }

  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<pageCount, id: \.self) { index in
        Circle()
          .fill(index == selection ? Color.primary : Color.secondary.opacity(0.4))
          .frame(width: 6, height: 6)
      }
    }
    .padding(.bottom, 8)
    .animation(.snappy, value: selection)
  }
}
