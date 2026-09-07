enum LabVariant: CaseIterable {
  case scrollView
  case tabView
  case fix

  var title: String {
    switch self {
    case .scrollView: "ScrollView"
    case .tabView: "TabView"
    case .fix: "ScrollView + fix"
    }
  }
}
