import SwiftUI

// MARK: - Why Not TabView

/// Each demo is a working paged `ScrollView` using an API that `TabView(.page)`
/// does not offer. Together they explain why we cannot adopt `TabView` even
/// though it survives window resizes natively.
struct WhyNotTabViewView: View {
  @State private var isSwipeLocked = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 32) {
        demoSection(
          title: "1 · Interactive parallax",
          caption: "scrollTransition(.interactive) drives a per-page, drag-tracked offset. "
            + "TabView exposes no per-page transition phase."
        ) {
          parallaxDemo
        }

        demoSection(
          title: "2 · Peeking carousel",
          caption: "Pages narrower than the container, centered via contentMargins, neighbors visible. "
            + "TabView pages are always exactly container-sized."
        ) {
          peekingDemo
        }

        demoSection(
          title: "3 · Inter-page spacing",
          caption: "A visible gutter between pages during the swipe (HStack spacing). "
            + "TabView has no inter-page spacing option."
        ) {
          spacingDemo
        }

        demoSection(
          title: "4 · Conditional swipe lock",
          caption: "scrollDisabled(_:) suspends paging while a child gesture owns the touch "
            + "(pinch-to-zoom, pull-to-dismiss). TabView cannot suspend its swipe."
        ) {
          VStack(spacing: 8) {
            Toggle("Lock swipe", isOn: $isSwipeLocked)
              .padding(.horizontal, 16)
            swipeLockDemo
          }
        }

        notesSection
      }
      .padding(.vertical, 16)
    }
    .navigationTitle("Why not TabView(.page)")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: - Demos

  private var parallaxDemo: some View {
    pagedScrollView { index in
      demoPage(index: index)
        .containerRelativeFrame(.horizontal)
        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
          content.offset(x: phase.value * 24)
        }
    }
  }

  private var peekingDemo: some View {
    GeometryReader { geometry in
      ScrollView(.horizontal) {
        HStack(spacing: 12) {
          ForEach(0..<5, id: \.self) { index in
            demoPage(index: index)
              .frame(width: 220)
          }
        }
        .scrollTargetLayout()
      }
      .contentMargins(.horizontal, max(0, (geometry.size.width - 220) / 2), for: .scrollContent)
      .scrollTargetBehavior(.viewAligned)
      .scrollIndicators(.hidden)
      .scrollClipDisabled()
    }
    .frame(height: 140)
  }

  private var spacingDemo: some View {
    pagedScrollView(spacing: 10) { index in
      demoPage(index: index)
        .containerRelativeFrame(.horizontal)
    }
  }

  private var swipeLockDemo: some View {
    pagedScrollView { index in
      demoPage(index: index)
        .containerRelativeFrame(.horizontal)
    }
    .scrollDisabled(isSwipeLocked)
  }

  // MARK: - Building Blocks

  private func pagedScrollView(
    spacing: CGFloat = 0,
    @ViewBuilder page: @escaping (Int) -> some View
  ) -> some View {
    ScrollView(.horizontal) {
      HStack(spacing: spacing) {
        ForEach(0..<5, id: \.self) { index in
          page(index)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollIndicators(.hidden)
    .frame(height: 140)
  }

  private func demoPage(index: Int) -> some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(index.isMultiple(of: 2) ? Color(.secondarySystemBackground) : Color(.tertiarySystemBackground))
      .overlay {
        Text("\(index)")
          .font(.title.bold())
      }
  }

  private func demoSection(
    title: String,
    caption: String,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .padding(.horizontal, 16)
      Text(caption)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
      content()
    }
  }

  private var notesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Also required by our pagers, with no TabView equivalent")
        .font(.headline)
      Text(
        """
        • Continuous scroll progress (onScrollGeometryChange) driving an animated \
        tab-indicator underline.
        • Fixed chrome via overlay(alignment: .top) — e.g. a gradient scrim above the pager \
        that must not participate in paging and must ignore the safe area. Inside TabView \
        this fights the container's own safe-area handling; safe-area issues previously \
        forced us to replace TabView with a UIKit UIScrollView wrapper.
        • Eager (non-lazy) page realization to avoid dissolve/re-materialize artifacts \
        during animated non-adjacent page jumps.
        """
      )
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 16)
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    WhyNotTabViewView()
  }
}
