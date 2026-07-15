import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allScheduleRules: [ScheduleRule]
    @Query private var allLogs: [WorkoutLog]
    @Query(filter: #Predicate<WorkoutType> { !$0.isArchived })
    private var availableWorkoutTypes: [WorkoutType]

    @State private var showUnscheduledPicker = false
    @State private var selectedEditingLog: WorkoutLog? = nil
    @State private var editingActualValue: Double = 0.0
    @State private var editingNotes: String = ""

    private let today = Calendar.current.startOfDay(for: Date())
    private let currentDayOfWeek = Calendar.current.component(.weekday, from: Date())

    private var todaysRules: [ScheduleRule] {
        allScheduleRules.filter { $0.dayOfWeek == currentDayOfWeek }
    }

    private var todaysLogs: [WorkoutLog] {
        allLogs.filter { Calendar.current.startOfDay(for: $0.date) == today }
    }

    private var completedCount: Int {
        todaysLogs.filter { $0.isCompleted }.count
    }

    private var progressFraction: Double {
        guard !todaysRules.isEmpty else { return 0.0 }
        return Double(completedCount) / Double(todaysRules.count)
    }

    private var completedRuleIds: Set<UUID> {
        Set(todaysLogs.filter { $0.isCompleted }.compactMap { $0.workoutType?.id })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    dateHeader
                    progressSection
                    workoutListSection
                    unscheduledSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today's Workout")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedEditingLog) { log in
                editLogView(for: log)
            }
            .sheet(isPresented: $showUnscheduledPicker) {
                unscheduledWorkoutPicker
            }
        }
    }

    // MARK: - Date Header
    private var dateHeader: some View {
        VStack(spacing: 4) {
            Text(today.dayName)
                .font(.title.bold())
                .foregroundStyle(.primary)
            Text(today.formattedDate)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                Text("\(completedCount) / \(todaysRules.count) completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progressFraction)
                .progressViewStyle(.linear)
                .tint(progressFraction >= 1.0 ? .green : .blue)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            if progressFraction >= 1.0 && !todaysRules.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("All done! Great work today!")
                        .font(.caption.bold())
                }
                .foregroundStyle(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - Workout List
    private var workoutListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Scheduled Today")
                    .font(.headline)
                Spacer()
            }

            if todaysRules.isEmpty {
                emptyStateView
            } else {
                ForEach(todaysRules, id: \.id) { rule in
                    workoutRow(for: rule)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - Unscheduled Section
    private var unscheduledSection: some View {
        VStack(spacing: 10) {
            if !todaysLogs.filter({ log in
                !todaysRules.contains(where: { $0.workoutType?.id == log.workoutType?.id })
            }).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Extra Workouts")
                        .font(.headline)
                    ForEach(todaysLogs.filter { log in
                        !todaysRules.contains(where: { $0.workoutType?.id == log.workoutType?.id })
                    }) { log in
                        unscheduledLogRow(log)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                )
                .padding(.horizontal)
            }

            Button {
                showUnscheduledPicker = true
            } label: {
                Label("Add Unscheduled Workout", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No workouts scheduled for today.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            NavigationLink(destination: SchedulePlannerView()) {
                Text("Go to Schedule Planner")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.blue))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Workout Row
    @ViewBuilder
    private func workoutRow(for rule: ScheduleRule) -> some View {
        if let workoutType = rule.workoutType {
            let log = todaysLogs.first { $0.workoutType?.id == workoutType.id }
            let isDone = log?.isCompleted ?? false

            HStack(spacing: 14) {
                Button {
                    toggleCompletion(for: rule, existingLog: log)
                } label: {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isDone ? .green : .gray.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(workoutType.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    HStack(spacing: 4) {
                        Image(systemName: workoutType.metricType.systemImage)
                            .font(.caption2)
                        Text(targetDescription(for: rule, workoutType: workoutType))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if let log = log {
                    Button {
                        selectedEditingLog = log
                    } label: {
                        HStack(spacing: 4) {
                            Text(formattedValue(log.actualValue, metric: workoutType.metricType))
                                .font(.caption.weight(.semibold))
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.blue.opacity(0.1)))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func unscheduledLogRow(_ log: WorkoutLog) -> some View {
        if let workoutType = log.workoutType {
            HStack(spacing: 14) {
                Image(systemName: "star.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(workoutType.name)
                        .font(.body.weight(.medium))
                    Text("Unscheduled · \(formattedValue(log.actualValue, metric: workoutType.metricType))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    selectedEditingLog = log
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Edit Log Sheet
    private func editLogView(for log: WorkoutLog) -> some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    HStack {
                        Text("Exercise")
                        Spacer()
                        Text(log.workoutType?.name ?? "Unknown")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Recorded Value") {
                    if let workoutType = log.workoutType, workoutType.metricType != .completionOnly {
                        HStack {
                            Text(workoutType.metricType.unitLabel.capitalized)
                            Spacer()
                            TextField("0", value: $editingActualValue, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                        Stepper("Adjust", value: $editingActualValue, step: stepIncrement(for: workoutType.metricType))
                    }

                    Toggle("Completed", isOn: Binding(get: {
                        log.isCompleted
                    }, set: { newValue in
                        log.isCompleted = newValue
                    }))
                }

                Section("Notes") {
                    TextField("Optional notes...", text: $editingNotes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedEditingLog = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        log.actualValue = editingActualValue
                        log.notes = editingNotes.isEmpty ? nil : editingNotes
                        log.isCompleted = editingActualValue > 0 || log.isCompleted
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to save log: \(error)")
                        }
                        selectedEditingLog = nil
                    }
                }
            }
            .onAppear {
                editingActualValue = log.actualValue
                editingNotes = log.notes ?? ""
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Unscheduled Picker
    private var unscheduledWorkoutPicker: some View {
        NavigationStack {
            List {
                ForEach(availableWorkoutTypes.filter { type in
                    !todaysRules.contains { $0.workoutType?.id == type.id }
                }) { workoutType in
                    Button {
                        addUnscheduledWorkout(workoutType)
                        showUnscheduledPicker = false
                    } label: {
                        HStack {
                            Circle()
                                .fill(colorFromHex(workoutType.colorHex))
                                .frame(width: 12, height: 12)
                            Text(workoutType.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(workoutType.category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showUnscheduledPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Actions
    private func toggleCompletion(for rule: ScheduleRule, existingLog: WorkoutLog?) {
        if let log = existingLog {
            log.isCompleted.toggle()
            if !log.isCompleted {
                log.actualValue = 0
            } else if log.actualValue == 0 {
                log.actualValue = rule.effectiveTargetValue
            }
            do {
                try modelContext.save()
            } catch {
                print("Failed to toggle completion: \(error)")
            }
        } else if let workoutType = rule.workoutType {
            let newLog = WorkoutLog(
                date: today,
                workoutType: workoutType,
                actualValue: rule.effectiveTargetValue,
                isCompleted: true
            )
            modelContext.insert(newLog)
            do {
                try modelContext.save()
            } catch {
                print("Failed to save new log: \(error)")
            }
        }
    }

    private func addUnscheduledWorkout(_ workoutType: WorkoutType) {
        let newLog = WorkoutLog(
            date: today,
            workoutType: workoutType,
            actualValue: workoutType.defaultTargetValue,
            isCompleted: true
        )
        modelContext.insert(newLog)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save unscheduled workout: \(error)")
        }
    }

    // MARK: - Helpers
    private func targetDescription(for rule: ScheduleRule, workoutType: WorkoutType) -> String {
        let target = rule.effectiveTargetValue
        let unit = workoutType.metricType.unitLabel
        if workoutType.metricType == .completionOnly {
            return "Complete"
        }
        return unit.isEmpty
            ? "Target: \(String(format: "%.0f", target))"
            : "Target: \(String(format: target.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", target)) \(unit)"
    }

    private func formattedValue(_ value: Double, metric: MetricType) -> String {
        if metric == .completionOnly {
            return value > 0 ? "Done" : "0"
        }
        let fmt = value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"
        return "\(String(format: fmt, value)) \(metric.unitLabel)"
    }

    private func stepIncrement(for metric: MetricType) -> Double {
        switch metric {
        case .reps: return 1.0
        case .durationMinutes: return 5.0
        case .distanceKm: return 0.5
        case .completionOnly: return 1.0
        }
    }
}
