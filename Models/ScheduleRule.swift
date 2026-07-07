import Foundation
import SwiftData

@Model
final class ScheduleRule {
    @Attribute(.unique) var id: UUID
    var dayOfWeek: Int
    var customTargetValue: Double?

    // SwiftData auto-infers inverse dari WorkoutType.scheduleRules
    var workoutType: WorkoutType?

    var dayName: String {
        let names = [
            1: "Sunday", 2: "Monday", 3: "Tuesday",
            4: "Wednesday", 5: "Thursday", 6: "Friday", 7: "Saturday"
        ]
        return names[dayOfWeek] ?? "Unknown"
    }

    var shortDayName: String {
        let names = [
            1: "Sun", 2: "Mon", 3: "Tue",
            4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"
        ]
        return names[dayOfWeek] ?? "?"
    }

    var effectiveTargetValue: Double {
        if let customValue = customTargetValue {
            return customValue
        }
        return workoutType?.defaultTargetValue ?? 0.0
    }

    init(
        id: UUID = UUID(),
        dayOfWeek: Int,
        workoutType: WorkoutType? = nil,
        customTargetValue: Double? = nil
    ) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.workoutType = workoutType
        self.customTargetValue = customTargetValue
    }
}
