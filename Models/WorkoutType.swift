import Foundation
import SwiftData

enum WorkoutCategory: String, CaseIterable, Codable {
    case strength = "Strength"
    case cardio = "Cardio"
    case flexibility = "Flexibility"
    case custom = "Custom"

    var displayName: String { rawValue }

    var systemImage: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .cardio: return "heart.circle"
        case .flexibility: return "figure.mind.and.body"
        case .custom: return "star.circle"
        }
    }
}

enum MetricType: String, CaseIterable, Codable {
    case reps = "reps"
    case durationMinutes = "duration_minutes"
    case distanceKm = "distance_km"
    case completionOnly = "completion_only"

    var displayName: String {
        switch self {
        case .reps: return "Reps"
        case .durationMinutes: return "Duration (min)"
        case .distanceKm: return "Distance (km)"
        case .completionOnly: return "Checkbox / Done"
        }
    }

    var unitLabel: String {
        switch self {
        case .reps: return "reps"
        case .durationMinutes: return "min"
        case .distanceKm: return "km"
        case .completionOnly: return ""
        }
    }

    var systemImage: String {
        switch self {
        case .reps: return "repeat.circle"
        case .durationMinutes: return "timer.circle"
        case .distanceKm: return "figure.walk.circle"
        case .completionOnly: return "checkmark.circle"
        }
    }
}

@Model
final class WorkoutType {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var metricTypeRaw: String
    var defaultTargetValue: Double
    var colorHex: String
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \ScheduleRule.workoutType)
    var scheduleRules: [ScheduleRule]?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutLog.workoutType)
    var workoutLogs: [WorkoutLog]?

    var category: WorkoutCategory {
        get { WorkoutCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }

    var metricType: MetricType {
        get { MetricType(rawValue: metricTypeRaw) ?? .reps }
        set { metricTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: WorkoutCategory = .custom,
        metricType: MetricType = .reps,
        defaultTargetValue: Double = 10.0,
        colorHex: String = "#007AFF",
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.metricTypeRaw = metricType.rawValue
        self.defaultTargetValue = defaultTargetValue
        self.colorHex = colorHex
        self.isArchived = isArchived
    }
}
