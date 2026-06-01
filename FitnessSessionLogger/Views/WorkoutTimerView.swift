import SwiftUI

struct WorkoutTimerView: View {
    @State private var workoutSeconds = 0
    @State private var restSeconds = 90
    @State private var selectedRestSeconds = 90
    @State private var isWorkoutRunning = false
    @State private var isRestRunning = false
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                Section("Общее время тренировки") {
                    VStack(spacing: 16) {
                        Text(format(workoutSeconds))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)

                        HStack {
                            Button(isWorkoutRunning ? "Пауза" : "Старт") { toggleWorkout() }
                                .buttonStyle(.borderedProminent)
                            Button("Сброс") { resetWorkout() }
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Отдых между подходами") {
                    Picker("Время отдыха", selection: $selectedRestSeconds) {
                        Text("60 сек").tag(60)
                        Text("90 сек").tag(90)
                        Text("120 сек").tag(120)
                        Text("180 сек").tag(180)
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 16) {
                        Text(format(restSeconds))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(isRestRunning ? .primary : .secondary)

                        HStack {
                            Button(isRestRunning ? "Пауза отдыха" : "Начать отдых") { toggleRest() }
                                .buttonStyle(.borderedProminent)
                            Button("Заново") { resetRest() }
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Подсказка") {
                    Text("После тяжёлого подхода нажимай «Начать отдых». Для ягодичного моста и румынки часто удобно 90–180 секунд, для изоляции 60–90 секунд.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Таймер")
            .onChange(of: selectedRestSeconds) { _, newValue in
                if !isRestRunning { restSeconds = newValue }
            }
            .onDisappear { timerTask?.cancel() }
        }
    }

    private func toggleWorkout() {
        isWorkoutRunning.toggle()
        restartTimerTask()
    }

    private func toggleRest() {
        if restSeconds == 0 { restSeconds = selectedRestSeconds }
        isRestRunning.toggle()
        restartTimerTask()
    }

    private func resetWorkout() {
        isWorkoutRunning = false
        workoutSeconds = 0
        restartTimerTask()
    }

    private func resetRest() {
        isRestRunning = false
        restSeconds = selectedRestSeconds
        restartTimerTask()
    }

    private func restartTimerTask() {
        timerTask?.cancel()
        guard isWorkoutRunning || isRestRunning else { return }

        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }

                if isWorkoutRunning { workoutSeconds += 1 }
                if isRestRunning {
                    if restSeconds > 0 {
                        restSeconds -= 1
                    } else {
                        isRestRunning = false
                    }
                }
            }
        }
    }

    private func format(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
