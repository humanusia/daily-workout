import SwiftUI
import SwiftData

struct SchedulePlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutType> { !$0.isArchived })
    private var availableWorkoutTypes: [WorkoutType]

    @Query private var allScheduleRules: [ScheduleRule]

    @State private var selectedDay: Int = Calendar.current.component(.weekday, from: Date())
    @State private var showAddSheet = false
    @State private var showCustomTargetAlert = false
    @State private var selectedRuleForCustom: ScheduleRule? = nil
    @State private var customTargetInput: Double = 10.0

    private let days: [(index: Int, short: String)] = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"),
        (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat")
    ]

    private var rulesForSelectedDay: [ScheduleRule] {
        allScheduleRules.filter { $0.dayOfWeek == selectedDay }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayPickerBar

                if rulesForSelectedDay.isEmpty {
                    emptyDayView
                } else {
                    dayWorkoutList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Schedule Planner")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !rulesForSelectedDay.isEmpty {
                        addButton
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                addWorkoutSheet
            }
        }
    }

    // MARK: - Day Picker
    private var dayPickerBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days, id: \.index) { day in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDay = day.index
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(day.short)
                                .font(.caption.weight(.semibold))
                            Circle()
                                .fill(selectedDay == day.index ? Color.blue : Color.clear)
                                .frame(width: 8, height: 8)
                        }
                        .foregroundStyle(selectedDay == day.index ? .blue : .secondary)
                        .frame(width: 52, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedDay == day.index
                                    ? .blue.opacity(0.1)
                                    : .clear
                                )
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
    }

    // MARK: - Day Workout List
    private var dayWorkoutList: some View {
        List {
            Section("\(dayName) Workouts") {
                ForEach(rulesForSelectedDay, id: \.id) { rule in
                    scheduleRuleRow(rule)
                }
                .onDelete(perform: deleteRules)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State
    private var emptyDayView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 52))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("No workouts scheduled for \(dayName)")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Tap the add button to build your \(dayName) routine.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            Button {
                showAddSheet = true
            } label: {
                Label("Add Workouts to \(dayName)", systemImage: "plus.circle.fill")
                    .font(.body.weight(.medium))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.blue))
                    .foregroundColor(.white)
            }
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Schedule Rule Row
    private func scheduleRuleRow(_ rule: ScheduleRule) -> some View {
        guard let workoutType = rule.workoutType else {
            return AnyView(EmptyView())
        }

        return AnyView(
            HStack(spacing: 12) {
                Circle()
                    .fill(colorFromHex(workoutType.colorHex))
                    .frame(width: 14, height: 14)

                VStack(alignment: .leading, spacing: 2) {
                    Text(workoutType.name)
                        .font(.body.weight(.medium))
                    HStack(spacing: 4) {
                        Text(workoutType.category.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(metricDescription(for: rule, workoutType: workoutType))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    selectedRuleForCustom = rule
                    customTargetInput = rule.customTargetValue ?? workoutType.defaultTargetValue
                    showCustomTargetAlert = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundStyle(rule.customTargetValue != nil ? .orange : .secondary)
                }
            }
            .padding(.vertical, 4)
            .alert("Custom Target", isPresented: $showCustomTargetAlert) {
                TextField("Value", value: $customTargetInput, format: .number)
                    .keyboardType(.decimalPad)
                Button("Use Default") {
                    if let rule = selectedRuleForCustom {
                        rule.customTargetValue = nil
                        saveContext()
                    }
                }
                Button("Save") {
                    if let rule = selectedRuleForCustom {
                        rule.customTargetValue = customTargetInput > 0 ? customTargetInput : nil
                        saveContext()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Set a custom target for this workout on \(dayName).\nDefault: \(workoutType.defaultTargetValue.formatted())")
            }
        )
    }

    // MARK: - Add Workout Sheet
    private var addWorkoutSheet: some View {
        NavigationStack {
            List {
                ForEach(availableWorkoutTypes.filter { type in
                    !rulesForSelectedDay.contains { $0.workoutType?.id == type.id }
                }) { workoutType in
                    Button {
                        addWorkoutToDay(workoutType)
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(colorFromHex(workoutType.colorHex))
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(workoutType.name)
                                    .foregroundStyle(.primary)
                                Text(workoutType.category.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Add Workout to \(dayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showAddSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Add Button
    private var addButton: some View {
        Button {
            showAddSheet = true
        } label: {
            Image(systemName: "plus")
                .fontWeight(.semibold)
        }
    }

    // MARK: - Helpers
    private var dayName: String {
        days.first(where: { $0.index == selectedDay })?.short ?? "Day"
    }

    private func metricDescription(for rule: ScheduleRule, workoutType: WorkoutType) -> String {
        let target = rule.effectiveTargetValue
        if workoutType.metricType == .completionOnly {
            return "Complete"
        }
        let unit = workoutType.metricType.unitLabel
        let fmt = target.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"
        return "\(String(format: fmt, target)) \(unit)"
    }

    private func addWorkoutToDay(_ workoutType: WorkoutType) {
        let rule = ScheduleRule(
            dayOfWeek: selectedDay,
            workoutType: workoutType
        )
        modelContext.insert(rule)
        saveContext()
        showAddSheet = false
    }

    private func deleteRules(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(rulesForSelectedDay[index])
        }
        saveContext()
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("SchedulePlannerView save failed: \(error)")
        }
    }
}
