import SwiftUI
import PhotosUI
import UIKit

struct AddWorkoutView: View {
    let allExercises: [Exercise]
    let onSave: (WorkoutSession) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddWorkoutViewModel()
    @State private var isShowingExercisePicker = false
    @State private var isShowingPhotoPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Тренировка") {
                    TextField("Название", text: $viewModel.title)
                    Picker("Тип", selection: $viewModel.type) {
                        ForEach(WorkoutType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    DatePicker("Дата", selection: $viewModel.date)
                    Stepper("Длительность: \(viewModel.durationMinutes) мин", value: $viewModel.durationMinutes, in: 5...240, step: 5)
                    TextField("Заметка", text: $viewModel.note, axis: .vertical)
                }

                Section("Фото") {
                    if let data = viewModel.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Text("Можно добавить фото тренажёра, зала или результата тренировки.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button { isShowingPhotoPicker = true } label: {
                        Label(viewModel.photoData == nil ? "Добавить фото" : "Заменить фото", systemImage: "photo")
                    }

                    if viewModel.photoData != nil {
                        Button(role: .destructive) {
                            viewModel.photoData = nil
                        } label: {
                            Label("Удалить фото", systemImage: "trash")
                        }
                    }
                }

                Section("Упражнения") {
                    if viewModel.selectedExercises.isEmpty {
                        Text("Упражнения пока не добавлены")
                            .foregroundStyle(.secondary)
                    }

                    ForEach($viewModel.selectedExercises) { $logged in
                        exerciseEditor(logged: $logged)
                    }
                    .onDelete { offsets in
                        viewModel.removeExercise(at: offsets)
                    }

                    Button { isShowingExercisePicker = true } label: {
                        Label("Добавить упражнение", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Новая тренировка")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        onSave(viewModel.buildWorkout())
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .sheet(isPresented: $isShowingExercisePicker) {
                ExercisePickerView(exercises: allExercises) { exercise in
                    viewModel.addExercise(exercise)
                }
            }
            .sheet(isPresented: $isShowingPhotoPicker) {
                PhotoPickerView { data in
                    viewModel.photoData = data
                }
            }
        }
    }

    @ViewBuilder
    private func exerciseEditor(logged: Binding<LoggedExercise>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(logged.wrappedValue.exercise.name)
                .font(.headline)
            Text("\(logged.wrappedValue.exercise.muscle) • \(logged.wrappedValue.exercise.equipment)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(logged.wrappedValue.exercise.instructions)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            ForEach(logged.sets) { $set in
                HStack(spacing: 12) {
                    Stepper("\(set.reps) повт.", value: $set.reps, in: 1...100)

                    TextField("Вес", value: $set.weight, format: .number.precision(.fractionLength(0...1)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                    Text("кг")
                        .foregroundStyle(.secondary)

                    Button(role: .destructive) {
                        viewModel.removeSet(exerciseID: logged.wrappedValue.id, setID: set.id)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                }
                .font(.subheadline)
            }

            Button {
                viewModel.addSet(to: logged.wrappedValue.id)
            } label: {
                Label("Добавить подход", systemImage: "plus")
            }
            .font(.subheadline)
        }
        .padding(.vertical, 6)
    }
}


struct PhotoPickerView: UIViewControllerRepresentable {
    let onImagePicked: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImagePicked: (Data) -> Void
        let dismiss: DismissAction

        init(onImagePicked: @escaping (Data) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            dismiss()
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage,
                      let data = image.jpegData(compressionQuality: 0.75) else { return }
                Task { @MainActor in
                    self.onImagePicked(data)
                }
            }
        }
    }
}
