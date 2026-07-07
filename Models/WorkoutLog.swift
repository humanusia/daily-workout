import Foundation
import SwiftData

@Model
final class WorkoutLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var actualValue: Double
    var isCompleted: Bool
    var notes: String?

    // SwiftData auto-infers inverse dari WorkoutType.workoutLogs
    var workoutType: WorkoutType?

    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        workoutType: WorkoutType? = nil,
        actualValue: Double = 0.0,
        isCompleted: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.workoutType = workoutType
        self.actualValue = actualValue
        self.isCompleted = isCompleted
        self.notes = notes
    }
}
