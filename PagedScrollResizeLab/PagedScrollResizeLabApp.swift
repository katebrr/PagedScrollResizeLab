import SwiftUI

@main
struct PagedScrollResizeLabApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        List {
          Section {
            NavigationLink("Paged Resize Lab") {
              ResizeLabView()
            }
            NavigationLink("Why not TabView(.page)") {
              WhyNotTabViewView()
            }
          } footer: {
            Text(
              """
              Run on an iPad (iOS 27) and resize the window while on page 2+ of each \
              Resize Lab variant. Variants A–C lose page alignment; D (TabView) and \
              E (workaround) survive.
              """
            )
          }
        }
        .navigationTitle("Paged ScrollView vs Resize")
      }
    }
  }
}
