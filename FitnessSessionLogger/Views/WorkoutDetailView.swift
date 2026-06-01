import SwiftUI
import UIKit

struct WorkoutDetailView: View {
    @State private var workout: WorkoutSession
    @State private var isEditing = false
    let onUpdate: (WorkoutSession) -> Void

    init(workout: WorkoutSession, onUpdate: @escaping (WorkoutSession) -> Void) {
        self._workout = State(initialValue: workout)
        self.onUpdate = onUpdate
    }

    var body: some View {
        List {
            Section("Итоги") {
                LabeledContent("Тип", value: workout.type.rawValue)
                LabeledContent("Длительность", value: "\(workout.durationMinutes) мин")
                LabeledContent("Всего подходов", value: "\(workout.totalSets)")
                if !workout.note.isEmpty { Text(workout.note) }
            }

            if let data = workout.photoData, let image = UIImage(data: data) {
                Section("Фото") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            Section("Упражнения") {
                ForEach($workout.exercises) { $logged in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(logged.exercise.name).font(.headline)
                        Text(logged.exercise.instructions)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach($logged.sets) { $set in
                            if isEditing {
                                HStack(spacing: 12) {
                                    Stepper("\(set.reps) повт.", value: $set.reps, in: 1...100)
                                    TextField("Вес", value: $set.weight, format: .number.precision(.fractionLength(0...1)))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 70)
                                    Text("кг").foregroundStyle(.secondary)
                                }
                            } else {
                                HStack {
                                    Text("Подход")
                                    Spacer()
                                    Text("\(set.reps) повт. × \(set.weight, specifier: "%.1f") кг")
                                }
                            }
                        }

                        if isEditing {
                            Button {
                                let previous = logged.sets.last ?? ExerciseSet(reps: 10, weight: 0, note: "")
                                logged.sets.append(ExerciseSet(reps: previous.reps, weight: previous.weight, note: ""))
                            } label: {
                                Label("Добавить подход", systemImage: "plus")
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(workout.title)
        .toolbar {
            Button(isEditing ? "Сохранить" : "Изменить") {
                if isEditing { onUpdate(workout) }
                isEditing.toggle()
            }
        }
    }
}
