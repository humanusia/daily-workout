import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .today

    enum Tab: String, CaseIterable {
        case today = "Today"
        case schedule = "Schedule"
        case library = "Library"

        var systemImage: String {
            switch self {
            case .today: return "checklist.checked"
            case .schedule: return "calendar.badge.clock"
            case .library: return "square.grid.2x2"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label(Tab.today.rawValue, systemImage: Tab.today.systemImage)
                }
                .tag(Tab.today)

            SchedulePlannerView()
                .tabItem {
                    Label(Tab.schedule.rawValue, systemImage: Tab.schedule.systemImage)
                }
                .tag(Tab.schedule)

            CustomizationHubView()
                .tabItem {
                    Label(Tab.library.rawValue, systemImage: Tab.library.systemImage)
                }
                .tag(Tab.library)
        }
        .tint(.blue)
    }
}
