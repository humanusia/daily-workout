import Foundation
import SwiftData

enum DataSeeder {
    static func seedDefaultWorkoutTypes(in context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<WorkoutType>()
        guard let count = try? context.fetchCount(fetchDescriptor), count == 0 else {
            return
        }

        let defaults: [(name: String, category: WorkoutCategory, metric: MetricType, target: Double, hex: String)] = [
            ("Push Ups", .strength, .reps, 20.0, "#FF6B6B"),
            ("Pull Ups", .strength, .reps, 10.0, "#FF6B6B"),
            ("Squats", .strength, .reps, 30.0, "#FF6B6B"),
            ("Lunges", .strength, .reps, 20.0, "#FF6B6B"),
            ("Bench Press", .strength, .reps, 12.0, "#FF6B6B"),
            ("Plank", .strength, .durationMinutes, 2.0, "#4ECDC4"),
            ("Morning Jog", .cardio, .distanceKm, 5.0, "#45B7D1"),
            ("Cycling", .cardio, .distanceKm, 10.0, "#45B7D1"),
            ("Jump Rope", .cardio, .durationMinutes, 10.0, "#45B7D1"),
            ("Burpees", .cardio, .reps, 15.0, "#45B7D1"),
            ("Yoga Flow", .flexibility, .durationMinutes, 30.0, "#96CEB4"),
            ("Stretching", .flexibility, .durationMinutes, 15.0, "#96CEB4"),
            ("Pilates", .flexibility, .durationMinutes, 20.0, "#96CEB4"),
            ("Meditation", .flexibility, .durationMinutes, 10.0, "#FFEAA7"),
            ("Walking", .cardio, .durationMinutes, 30.0, "#45B7D1"),
        ]

        for item in defaults {
            let workout = WorkoutType(
                name: item.name,
                category: item.category,
                metricType: item.metric,
                defaultTargetValue: item.target,
                colorHex: item.hex
            )
            context.insert(workout)
        }

        do {
            try context.save()
            print("Seeded \(defaults.count) default workout types.")
        } catch {
            print("Failed to seed default workouts: \(error.localizedDescription)")
        }
    }
}
