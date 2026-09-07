import SwiftUI

/// Horizontal pager built on the standard SwiftUI paging recipe.
struct ScrollViewPager<Page: View>: View {
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
    ScrollView(.horizontal) {
      HStack(spacing: 0) {
        ForEach(0..<pageCount, id: \.self) { index in
          page(index)
            .containerRelativeFrame(.horizontal)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $selection)
    .scrollIndicators(.hidden)
  }
}
