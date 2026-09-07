import SwiftUI

/// Reproduces a paged `ScrollView` losing page alignment when its container
/// is resized, next to a `TabView(.page)` control and a workaround.
struct ResizeLabView: View {
  @State private var variant: LabVariant = .scrollView
  @State private var selection: Int? = 0
  @State private var metrics = ResizeLabMetrics()

  var body: some View {
    VStack(spacing: 16) {
      Picker("Variant", selection: $variant) {
        ForEach(LabVariant.allCases, id: \.self) { Text($0.title) }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 16)

      pager
        .overlay(alignment: .bottom) { pageIndicator }
        .clipped()

      ResizeLabReadout(metrics: metrics, selection: selection)
    }
    .padding(.vertical, 16)
    .navigationTitle("Paged Resize Lab")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: - Variants

  @ViewBuilder
  private var pager: some View {
    switch variant {
    case .scrollView:
      scrollPager
    case .tabView:
      tabViewPager
    case .fix:
      scrollPager
        .preservesScrollPosition(of: selection)
    }
  }

  private var scrollPager: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 0) {
        ForEach(0..<LabVariant.pageCount, id: \.self) { index in
          LabPage(index: index)
            .containerRelativeFrame(.horizontal)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: recordingBinding)
    .scrollIndicators(.hidden)
    .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.x } action: { _, newValue in
      metrics.contentOffsetX = newValue
    }
    .onScrollPhaseChange { _, newPhase, _ in
      metrics.scrollPhase = String(describing: newPhase)
    }
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: {
      metrics.containerWidth = $0
    }
  }

  private var tabViewPager: some View {
    TabView(selection: Binding(
      get: { selection ?? 0 },
      set: { newValue in
        metrics.recordSelectionWrite(newValue)
        selection = newValue
      }
    )) {
      ForEach(0..<LabVariant.pageCount, id: \.self) { index in
        LabPage(index: index)
          .tag(index)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: {
      metrics.containerWidth = $0
    }
  }

  private var recordingBinding: Binding<Int?> {
    Binding(
      get: { selection },
      set: { newValue in
        metrics.recordSelectionWrite(newValue)
        selection = newValue
      }
    )
  }

  private var pageIndicator: some View {
    HStack(spacing: 8) {
      ForEach(0..<LabVariant.pageCount, id: \.self) { index in
        Circle()
          .fill(index == selection ? Color.primary : Color.secondary.opacity(0.4))
          .frame(width: 6, height: 6)
      }
    }
    .padding(.bottom, 8)
    .animation(.snappy, value: selection)
  }
}

// MARK: - LabVariant

enum LabVariant: CaseIterable {
  case scrollView
  case tabView
  case fix

  static let pageCount = 5

  var title: String {
    switch self {
    case .scrollView: "ScrollView"
    case .tabView: "TabView"
    case .fix: "ScrollView + fix"
    }
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    ResizeLabView()
  }
}
