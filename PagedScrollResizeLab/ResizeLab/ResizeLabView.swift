import SwiftUI

/// Reproduces a paged `ScrollView` losing page alignment when its container
/// is resized, next to a `TabView(.page)` control and a workaround.
struct ResizeLabView: View {
  @State private var viewModel = ResizeLabViewModel()

  var body: some View {
    VStack(spacing: 16) {
      Picker("Variant", selection: $viewModel.variant) {
        ForEach(LabVariant.allCases, id: \.self) { Text($0.title) }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 16)

      pager
        .overlay(alignment: .bottom) {
          PageIndicator(pageCount: viewModel.pageCount, selection: viewModel.selection)
        }
        .clipped()

      ResizeLabReadout(viewModel: viewModel)
    }
    .padding(.vertical, 16)
    .navigationTitle("Paged Resize Lab")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: - Variants

  @ViewBuilder
  private var pager: some View {
    switch viewModel.variant {
    case .scrollView:
      scrollPager
    case .tabView:
      tabPager
    case .fix:
      scrollPager
        .preservesScrollPosition(of: viewModel.selection)
    }
  }

  private var scrollPager: some View {
    ScrollViewPager(pageCount: viewModel.pageCount, selection: selection) {
      LabPage(index: $0)
    }
    .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.x } action: { _, newValue in
      viewModel.updateContentOffset(newValue)
    }
    .onScrollPhaseChange { _, newPhase, _ in
      viewModel.updateScrollPhase(String(describing: newPhase))
    }
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: {
      viewModel.updateContainerWidth($0)
    }
  }

  private var tabPager: some View {
    TabViewPager(pageCount: viewModel.pageCount, selection: selection) {
      LabPage(index: $0)
    }
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: {
      viewModel.updateContainerWidth($0)
    }
  }

  private var selection: Binding<Int?> {
    Binding(
      get: { viewModel.selection },
      set: { viewModel.select($0) }
    )
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    ResizeLabView()
  }
}
