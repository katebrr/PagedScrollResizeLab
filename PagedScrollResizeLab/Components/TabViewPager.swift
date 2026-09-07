import SwiftUI

/// Horizontal pager built on `TabView(.page)`, the resize-surviving control case.
struct TabViewPager<Page: View>: View {
  private let pageCount: Int
  @Binding private var selection: Int?
  private let page: (Int) -> Page

  init(
    pageCount: Int,
    selection: Binding<Int?>,
    @ViewBuilder page: @escaping (Int) -> Page
  ) {
    self.pageCount = pageCount
    _selection = selection
    self.page = page
  }

  var body: some View {
    TabView(selection: nonOptionalSelection) {
      ForEach(0..<pageCount, id: \.self) { index in
        page(index)
          .tag(index)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
  }

  private var nonOptionalSelection: Binding<Int> {
    Binding(
      get: { selection ?? 0 },
      set: { selection = $0 }
    )
  }
}
