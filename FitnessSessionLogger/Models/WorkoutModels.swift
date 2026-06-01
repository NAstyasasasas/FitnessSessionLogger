import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var type: WorkoutType
    var muscle: String
    var equipment: String
    var difficulty: ExerciseDifficulty
    var instructions: String
}

enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case strength = "Силовая"
    case cardio = "Кардио"
    case mobility = "Мобилити"
    case fullBody = "Всё тело"
    case glutes = "Ягодицы"
    case upperBody = "Верх тела"
    case lowerBody = "Низ тела"

    var id: String { rawValue }
}

enum ExerciseDifficulty: String, Codable, CaseIterable, Identifiable {
    case beginner = "Начальный"
    case intermediate = "Средний"
    case advanced = "Продвинутый"

    var id: String { rawValue }
}

struct ExerciseSet: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var reps: Int
    var weight: Double
    var note: String
}

struct LoggedExercise: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var exercise: Exercise
    var sets: [ExerciseSet]
}

struct WorkoutSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var type: WorkoutType
    var date: Date
    var durationMinutes: Int
    var exercises: [LoggedExercise]
    var note: String
    var photoData: Data? = nil

    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets.count } }
    var totalVolume: Double {
        exercises.flatMap(\.sets).reduce(0) { $0 + Double($1.reps) * $1.weight }
    }
}

enum ViewState: Equatable {
    case loading
    case empty
    case content
    case error(String)
}
