import SwiftUI
import Lottie

struct WorkoutsListView: View {
    @Bindable var viewModel: WorkoutsViewModel
    @State private var isShowingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("Загружаю тренировки...")
                case .empty:
                    VStack(spacing: 16) {
                        LottieView(animation: .named("gym"))
                            .playing(loopMode: .loop)
                            .frame(width: 200, height: 200)

                        Text("Тренировок пока нет")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Добавь первую тренировку")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .error(let message):
                    ContentUnavailableView("Что-то пошло не так", systemImage: "exclamationmark.triangle", description: Text(message))
                case .content:
                    List {
                        filterSection
                        ForEach(viewModel.filteredWorkouts) { workout in
                            NavigationLink(value: workout) {
                                WorkoutRowView(workout: workout)
                            }
                        }
                        .onDelete { offsets in
                            Task { await viewModel.deleteWorkout(at: offsets) }
                        }
                    }
                    .searchable(text: $viewModel.searchText, prompt: "Поиск тренировок")
                }
            }
            .navigationTitle("Фитнес-дневник")
            .toolbar {
                Button { isShowingAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
            .navigationDestination(for: WorkoutSession.self) { workout in
                WorkoutDetailView(workout: workout) { updatedWorkout in
                    Task { await viewModel.updateWorkout(updatedWorkout) }
                }
            }
            .sheet(isPresented: $isShowingAdd) {
                AddWorkoutView(allExercises: viewModel.exercises) { workout in
                    Task { await viewModel.addWorkout(workout) }
                }
            }
        }
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                FilterChip(title: "Все", isSelected: viewModel.selectedFilter == nil) {
                    viewModel.setFilter(nil)
                }
                ForEach(WorkoutType.allCases) { type in
                    FilterChip(title: type.rawValue, isSelected: viewModel.selectedFilter == type) {
                        viewModel.setFilter(type)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listRowSeparator(.hidden)
    }
}
