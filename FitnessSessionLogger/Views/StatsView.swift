import SwiftUI
import Lottie


struct StatsView: View {
    @Bindable var viewModel: WorkoutsViewModel
    @State private var selectedDate: Date = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    weeklySummary
                    calendarBlock
                    selectedDayBlock
                }
                .padding()
            }
            .navigationTitle("Календарь")
        }
    }

    private var weeklySummary: some View {
        let currentWeek = workoutsInCurrentWeek
        return VStack(alignment: .leading, spacing: 12) {
            Text("Эта неделя")
                .font(.headline)

            HStack(spacing: 12) {
                SummaryCard(title: "Тренировок", value: "\(currentWeek.count)", icon: "calendar.badge.checkmark")
                SummaryCard(title: "Подходов", value: "\(currentWeek.reduce(0) { $0 + $1.totalSets })", icon: "list.number")
            }

            if currentWeek.isEmpty {
                Text("На этой неделе тренировок пока нет.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(currentWeek.map { $0.type.rawValue }.joined(separator: " • "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var calendarBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    moveMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()
                Text(monthTitle)
                    .font(.headline)
                Spacer()

                Button {
                    moveMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }

            HStack {
                ForEach(["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysForVisibleMonth, id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: selectedDate, toGranularity: .month),
                        workouts: workouts(on: date)
                    ) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var selectedDayBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Тренировки за день")
                .font(.headline)
            Text(dayTitle(selectedDate))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let dayWorkouts = workouts(on: selectedDate)
            if dayWorkouts.isEmpty {
                VStack(spacing: 12) {
                    LottieView(animation: .named("dumbbell"))
                        .playing(loopMode: .loop)
                        .frame(width: 160, height: 160)

                    Text("В этот день тренировок нет")
                        .font(.headline)

                    Text("Создайте тренировку или выберите другой день")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                ForEach(dayWorkouts) { workout in
                    NavigationLink {
                        WorkoutDetailView(workout: workout) { updatedWorkout in
                            Task { await viewModel.updateWorkout(updatedWorkout) }
                        }
                    } label: {
                        WorkoutRowView(workout: workout)
                            .padding()
                            .background(.background)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var workoutsInCurrentWeek: [WorkoutSession] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return viewModel.workouts.filter { week.contains($0.date) }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedDate).capitalized
    }

    private var daysForVisibleMonth: [Date] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
            let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
            let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1))
        else { return [] }

        var dates: [Date] = []
        var currentDate = monthFirstWeek.start
        while currentDate < monthLastWeek.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        return dates
    }

    private func workouts(on date: Date) -> [WorkoutSession] {
        viewModel.workouts
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    private func moveMonth(by value: Int) {
        selectedDate = calendar.date(byAdding: .month, value: value, to: selectedDate) ?? selectedDate
    }

    private func dayTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let workouts: [WorkoutSession]
    let action: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isCurrentMonth ? .primary : .secondary)

                if !workouts.isEmpty {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 42)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
