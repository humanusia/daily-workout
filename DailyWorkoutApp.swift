import SwiftUI
import SwiftData

@main
struct DailyWorkoutApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([WorkoutType.self, ScheduleRule.self, WorkoutLog.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            DataSeeder.seedDefaultWorkoutTypes(in: modelContainer.mainContext)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
