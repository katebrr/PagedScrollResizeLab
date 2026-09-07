import SwiftUI

// MARK: - Resize Lab

/// Reproduces the paged-scroll-loses-alignment-on-window-resize bug
/// against isolated pager variants, with live scroll instrumentation.
struct ResizeLabView: View {
  @State private var variant: LabVariant = .minimal
  @State private var snap: LabSnap = .paging
  @State private var selection: Int? = 0
  @State private var metrics = ResizeLabMetrics()

  var body: some View {
    VStack(spacing: 16) {
      Picker("Variant", selection: $variant) {
        ForEach(LabVariant.allCases, id: \.self) { Text($0.title) }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 16)

      Picker("Snap", selection: $snap) {
        ForEach(LabSnap.allCases, id: \.self) { Text($0.rawValue) }
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

  // MARK: - Pager Variants

  @ViewBuilder
  private var pager: some View {
    switch variant {
    case .minimal:
      scrollPager(selection: recordingBinding)
    case .shim:
      scrollPager(selection: shimBinding)
    case .productionShape:
      scrollPager(selection: shimBinding)
        .animation(.easeInOut, value: selection)
        .overlay(alignment: .top) { overlayBar }
    case .tabView:
      tabViewPager
    case .fix:
      scrollPager(selection: recordingBinding)
        .preservesScrollPosition(of: selection)
    }
  }

  private func scrollPager(selection: Binding<Int?>) -> some View {
    ScrollView(.horizontal) {
      HStack(spacing: 0) {
        ForEach(0..<LabVariant.pageCount, id: \.self) { index in
          LabPage(index: index)
            .containerRelativeFrame(.horizontal)
        }
      }
      .scrollTargetLayout()
    }
    .labSnapBehavior(snap)
    .scrollPosition(id: selection)
    .scrollIndicators(.hidden)
    .modifier(LabScrollInstrumentation(metrics: metrics))
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

  // MARK: - Selection Bindings

  private var recordingBinding: Binding<Int?> {
    Binding(
      get: { selection },
      set: { newValue in
        metrics.recordSelectionWrite(newValue)
        selection = newValue
      }
    )
  }

  /// The production shim: nil writes are recorded but swallowed.
  private var shimBinding: Binding<Int?> {
    Binding(
      get: { selection },
      set: { newValue in
        metrics.recordSelectionWrite(newValue)
        if let newValue { selection = newValue }
      }
    )
  }

  // MARK: - Chrome

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

  private var overlayBar: some View {
    HStack {
      Text("Overlay bar")
        .font(.caption.bold())
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color(.systemFill)))
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }
}

// MARK: - LabVariant

enum LabVariant: CaseIterable {
  case minimal
  case shim
  case productionShape
  case tabView
  case fix

  static let pageCount = 5

  var title: String {
    switch self {
    case .minimal: "A · Minimal"
    case .shim: "B · Nil shim"
    case .productionShape: "C · Production"
    case .tabView: "D · TabView"
    case .fix: "E · Fix"
    }
  }
}

// MARK: - LabSnap

enum LabSnap: String, CaseIterable {
  case paging
  case viewAligned
}

private extension View {
  @ViewBuilder
  func labSnapBehavior(_ snap: LabSnap) -> some View {
    switch snap {
    case .paging: scrollTargetBehavior(.paging)
    case .viewAligned: scrollTargetBehavior(.viewAligned)
    }
  }
}

// MARK: - LabScrollInstrumentation

private struct LabScrollInstrumentation: ViewModifier {
  let metrics: ResizeLabMetrics

  func body(content: Content) -> some View {
    content
      .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.x } action: { _, newValue in
        metrics.contentOffsetX = newValue
      }
      .onScrollPhaseChange { _, newPhase, _ in
        metrics.scrollPhase = String(describing: newPhase)
      }
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    ResizeLabView()
  }
}
