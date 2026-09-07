import SwiftUI

/// Horizontal pager built on `TabView(.page)`.
struct TabViewPager<Page: View>: View {
  private let pages: [Int]
  @Binding private var selection: Int?
  private let page: (Int) -> Page

  init(
    pages: [Int],
    selection: Binding<Int?>,
    @ViewBuilder page: @escaping (Int) -> Page
  ) {
    self.pages = pages
    _selection = selection
    self.page = page
  }

  var body: some View {
    TabView(selection: nonOptionalSelection) {
      ForEach(pages, id: \.self) { index in
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
