import SwiftUI

struct ExercisePickerView: View {
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedType: WorkoutType?
    @State private var customExercises: [Exercise] = []
    @State private var isShowingAddCustomExercise = false

    private let customStorage = CustomExerciseStorage()

    private var allExercises: [Exercise] {
        exercises + customExercises
    }

    private var filtered: [Exercise] {
        allExercises
            .filter { selectedType == nil || $0.type == selectedType }
            .filter {
                searchText.isEmpty
                || $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.muscle.localizedCaseInsensitiveContains(searchText)
                || $0.equipment.localizedCaseInsensitiveContains(searchText)
            }
    }

    var body: some View {
        NavigationStack {
            List {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(title: "Все", isSelected: selectedType == nil) { selectedType = nil }
                        ForEach(WorkoutType.allCases) { type in
                            FilterChip(title: type.rawValue, isSelected: selectedType == type) { selectedType = type }
                        }
                    }
                }

                if filtered.isEmpty {
                    ContentUnavailableView(
                        "Ничего не найдено",
                        systemImage: "magnifyingglass",
                        description: Text("Попробуй изменить поиск или добавь своё упражнение.")
                    )
                }

                ForEach(filtered) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(exercise.name)
                                    .font(.headline)
                                if isCustom(exercise) {
                                    Text("Своё")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(.blue.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }

                            Text("\(exercise.muscle) • \(exercise.equipment) • \(exercise.difficulty.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(exercise.instructions)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteCustomExercises)
            }
            .searchable(text: $searchText, prompt: "Поиск упражнений")
            .navigationTitle("Упражнения")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isShowingAddCustomExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                customExercises = (try? customStorage.load()) ?? []
            }
            .sheet(isPresented: $isShowingAddCustomExercise) {
                AddCustomExerciseView { exercise in
                    customExercises.append(exercise)
                    try? customStorage.save(customExercises)
                }
            }
        }
    }

    private func isCustom(_ exercise: Exercise) -> Bool {
        customExercises.contains(where: { $0.id == exercise.id })
    }

    private func deleteCustomExercises(at offsets: IndexSet) {
        let visibleCustomExercises = filtered.filter { isCustom($0) }
        let idsToDelete = offsets.compactMap { index -> UUID? in
            guard index < filtered.count else { return nil }
            let exercise = filtered[index]
            return visibleCustomExercises.contains(where: { $0.id == exercise.id }) ? exercise.id : nil
        }
        customExercises.removeAll { idsToDelete.contains($0.id) }
        try? customStorage.save(customExercises)
    }
}

struct AddCustomExerciseView: View {
    let onSave: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: WorkoutType = .strength
    @State private var muscle = ""
    @State private var equipment = ""
    @State private var difficulty: ExerciseDifficulty = .beginner
    @State private var instructions = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !muscle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название", text: $name)
                    Picker("Тип", selection: $type) {
                        ForEach(WorkoutType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("Мышцы", text: $muscle)
                    TextField("Оборудование", text: $equipment)
                    Picker("Сложность", selection: $difficulty) {
                        ForEach(ExerciseDifficulty.allCases) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                }

                Section("Описание техники") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Своё упражнение")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        let exercise = Exercise(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            type: type,
                            muscle: muscle.trimmingCharacters(in: .whitespacesAndNewlines),
                            equipment: equipment.isEmpty ? "Свое упражнение" : equipment,
                            difficulty: difficulty,
                            instructions: instructions.isEmpty ? "Пользовательское упражнение. Технику можно дополнить позже." : instructions
                        )
                        onSave(exercise)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

final class CustomExerciseStorage {
    private let fileName = "custom_exercises.json"

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    func load() throws -> [Exercise] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Exercise].self, from: data)
    }

    func save(_ exercises: [Exercise]) throws {
        let data = try JSONEncoder().encode(exercises)
        try data.write(to: fileURL, options: [.atomic])
    }
}
