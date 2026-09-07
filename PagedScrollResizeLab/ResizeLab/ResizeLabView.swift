import SwiftUI

/// Paged `ScrollView` resize bug next to a `TabView(.page)` control and a workaround.
struct ResizeLabView: View {
  @State private var viewModel = ResizeLabViewModel()

  var body: some View {
    VStack(spacing: 16) {
      Picker("Variant", selection: variantBinding) {
        ForEach(LabVariant.allCases, id: \.self) { Text($0.title) }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 16)

      pager
        .overlay(alignment: .bottom) {
          PageIndicator(pageCount: viewModel.currentPages.count, selection: viewModel.currentSelection)
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
      scrollPager(for: .scrollView)
    case .tabView:
      tabPager
    case .fix:
      scrollPager(for: .fix)
        .preservesScrollPosition(of: viewModel.fixSelection)
    }
  }

  private func scrollPager(for variant: LabVariant) -> some View {
    ScrollViewPager(pages: viewModel.pages(for: variant), selection: selectionBinding(for: variant)) {
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
    TabViewPager(pages: viewModel.tabViewPages, selection: selectionBinding(for: .tabView)) {
      LabPage(index: $0)
    }
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: {
      viewModel.updateContainerWidth($0)
    }
  }

  // MARK: - Bindings

  private var variantBinding: Binding<LabVariant> {
    Binding(
      get: { viewModel.variant },
      set: { viewModel.switchVariant(to: $0) }
    )
  }

  private func selectionBinding(for variant: LabVariant) -> Binding<Int?> {
    Binding(
      get: { viewModel.selection(for: variant) },
      set: { viewModel.select($0, in: variant) }
    )
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    ResizeLabView()
  }
}
