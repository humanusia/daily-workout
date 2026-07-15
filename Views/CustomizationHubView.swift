import SwiftUI
import SwiftData

// MARK: - Color Helper (used across views)
func colorFromHex(_ hex: String) -> Color {
    let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    var int: UInt64 = 0
    guard Scanner(string: sanitized).scanHexInt64(&int) else { return .blue }
    let r = Double((int >> 16) & 0xFF) / 255.0
    let g = Double((int >> 8) & 0xFF) / 255.0
    let b = Double(int & 0xFF) / 255.0
    return Color(red: r, green: g, blue: b)
}

// MARK: - Predefined Color Palette
struct ColorPalette {
    static let options: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"),
        ("Red", "#FF3B30"),
        ("Orange", "#FF9500"),
        ("Yellow", "#FFCC00"),
        ("Green", "#34C759"),
        ("Mint", "#00C7BE"),
        ("Teal", "#30B0C7"),
        ("Cyan", "#32ADE6"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Coral", "#FF6B6B"),
        ("Indigo", "#5856D6"),
    ]
}

// MARK: - Customization Hub View
struct CustomizationHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutType> { !$0.isArchived }, sort: \WorkoutType.name)
    private var workoutTypes: [WorkoutType]

    @State private var showCreateForm = false
    @State private var selectedWorkoutType: WorkoutType? = nil
    @State private var showDeleteConfirmation = false
    @State private var workoutToDelete: WorkoutType? = nil

    private var groupedWorkouts: [(category: WorkoutCategory, items: [WorkoutType])] {
        let grouped = Dictionary(grouping: workoutTypes) { $0.category }
        return WorkoutCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if workoutTypes.isEmpty {
                    emptyLibraryView
                } else {
                    workoutLibraryList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateForm = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showCreateForm) {
                WorkoutFormView(mode: .create)
            }
            .sheet(item: $selectedWorkoutType) { workout in
                WorkoutFormView(mode: .edit(workout))
            }
            .alert("Delete Workout?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let workout = workoutToDelete {
                        deleteWorkout(workout)
                    }
                }
            } message: {
                Text("This will also remove all schedule rules and logs for this workout type.")
            }
        }
    }

    // MARK: - Empty State
    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "dumbbell")
                .font(.system(size: 52))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("No workouts yet")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Create your first workout type to get started.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button {
                showCreateForm = true
            } label: {
                Label("Create Workout", systemImage: "plus.circle.fill")
                    .font(.body.weight(.medium))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.blue))
                    .foregroundColor(.white)
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Library List
    private var workoutLibraryList: some View {
        List {
            ForEach(groupedWorkouts, id: \.category.rawValue) { group in
                Section {
                    ForEach(group.items) { workout in
                        workoutRow(workout)
                    }
                } header: {
                    HStack {
                        Image(systemName: group.category.systemImage)
                        Text(group.category.displayName)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func workoutRow(_ workout: WorkoutType) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(colorFromHex(workout.colorHex))
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.body.weight(.medium))
                HStack(spacing: 4) {
                    Image(systemName: workout.metricType.systemImage)
                        .font(.caption2)
                    Text(metricSummary(for: workout))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    selectedWorkoutType = workout
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                Button {
                    workoutToDelete = workout
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash.circle")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func metricSummary(for workout: WorkoutType) -> String {
        if workout.metricType == .completionOnly {
            return "Checkbox"
        }
        let fmt = workout.defaultTargetValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"
        let val = String(format: fmt, workout.defaultTargetValue)
        return "\(val) \(workout.metricType.unitLabel)"
    }

    private func deleteWorkout(_ workout: WorkoutType) {
        modelContext.delete(workout)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete workout: \(error)")
        }
    }
}

// MARK: - Workout Form View (Create / Edit)
struct WorkoutFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum Mode {
        case create
        case edit(WorkoutType)
    }

    let mode: Mode

    @State private var name: String = ""
    @State private var selectedCategory: WorkoutCategory = .strength
    @State private var selectedMetric: MetricType = .reps
    @State private var targetValue: Double = 10.0
    @State private var selectedColorHex: String = "#007AFF"

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var title: String {
        isEditing ? "Edit Workout" : "New Workout"
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                metricSection
                colorSection
                if isEditing {
                    deleteSection
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveWorkout()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if case .edit(let workout) = mode {
                    populateFromWorkout(workout)
                }
            }
        }
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        Section("Details") {
            TextField("Workout Name", text: $name)

            Picker("Category", selection: $selectedCategory) {
                ForEach(WorkoutCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.systemImage)
                        .tag(category)
                }
            }
        }
    }

    // MARK: - Metric Section
    private var metricSection: some View {
        Section("Metric & Target") {
            Picker("Metric Type", selection: $selectedMetric) {
                ForEach(MetricType.allCases, id: \.self) { metric in
                    Label(metric.displayName, systemImage: metric.systemImage)
                        .tag(metric)
                }
            }

            if selectedMetric != .completionOnly {
                HStack {
                    Text("Default Target")
                    Spacer()
                    TextField("Value", value: $targetValue, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text(selectedMetric.unitLabel)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Stepper("Adjust", value: $targetValue, step: stepIncrement, format: .number)
            } else {
                HStack {
                    Text("When completed, just check it off.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Color Section
    private var colorSection: some View {
        Section("Color Tag") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                ForEach(ColorPalette.options, id: \.hex) { option in
                    Button {
                        selectedColorHex = option.hex
                    } label: {
                        Circle()
                            .fill(colorFromHex(option.hex))
                            .frame(width: 36, height: 36)
                            .overlay {
                                if selectedColorHex == option.hex {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)

            ColorPicker("Custom Color", selection: Binding(
                get: { colorFromHex(selectedColorHex) },
                set: { selectedColorHex = hexFromColor($0) }
            ))
        }
    }

    // MARK: - Delete Section
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                if case .edit(let workout) = mode {
                    modelContext.delete(workout)
                    do {
                        try modelContext.save()
                    } catch {
                        print("Delete failed: \(error)")
                    }
                }
                dismiss()
            } label: {
                HStack {
                    Spacer()
                    Label("Delete Workout", systemImage: "trash")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Helpers
    private var stepIncrement: Double {
        switch selectedMetric {
        case .reps: return 1.0
        case .durationMinutes: return 5.0
        case .distanceKm: return 0.5
        case .completionOnly: return 1.0
        }
    }

    private func populateFromWorkout(_ workout: WorkoutType) {
        name = workout.name
        selectedCategory = workout.category
        selectedMetric = workout.metricType
        targetValue = workout.defaultTargetValue
        selectedColorHex = workout.colorHex
    }

    private func saveWorkout() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        switch mode {
        case .create:
            let newWorkout = WorkoutType(
                name: trimmedName,
                category: selectedCategory,
                metricType: selectedMetric,
                defaultTargetValue: selectedMetric == .completionOnly ? 1.0 : targetValue,
                colorHex: selectedColorHex
            )
            modelContext.insert(newWorkout)

        case .edit(let workout):
            workout.name = trimmedName
            workout.category = selectedCategory
            workout.metricType = selectedMetric
            workout.defaultTargetValue = selectedMetric == .completionOnly ? 1.0 : targetValue
            workout.colorHex = selectedColorHex
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save workout: \(error)")
        }
        dismiss()
    }
}

// MARK: - Color → Hex Conversion
private func hexFromColor(_ color: Color) -> String {
    let uiColor = UIColor(color)
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    let hex = String(
        format: "#%02X%02X%02X",
        Int(red * 255.99),
        Int(green * 255.99),
        Int(blue * 255.99)
    )
    return hex
}
