import SwiftUI
import SwiftData

/// Three-screen onboarding flow (User Journey 4.2).
/// Screen 1: Welcome  |  Screen 2: Interactive tutorial  |  Screen 3: First task creation
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var tutorialCompleted = false
    @State private var taskCreated = false

    /// Called when onboarding finishes (skip or complete).
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            TabView(selection: $currentPage) {
                welcomeScreen.tag(0)
                tutorialScreen.tag(1)
                firstTaskScreen.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Skip button — visible on all screens
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 20)
                    .padding(.top, 8)
                    .accessibilityIdentifier("skipOnboarding")
                }
                Spacer()
            }
        }
    }

    // MARK: - Screen 1: Welcome

    private var welcomeScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)

            Text("Small habits,\nmassive change.")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text("Track your daily habits and stay motivated.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.accentColor))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Screen 2: Interactive Tutorial

    private var tutorialScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Tap & Hold to Complete")
                .font(.title2.weight(.bold))

            Text("Press and hold the circle for 2 seconds to mark a habit as done.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Demo task — uses a fake HabitTask for the tutorial
            demoTaskView

            if tutorialCompleted {
                VStack(spacing: 12) {
                    Text("Your goal is to build a streak of consecutive days")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .transition(.opacity)

                    Button {
                        withAnimation { currentPage = 2 }
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.accentColor))
                    }
                    .padding(.horizontal, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            Spacer()
        }
        .animation(.easeInOut, value: tutorialCompleted)
    }

    private var demoTaskView: some View {
        let demoTask = HabitTask(
            title: "Walk the dog",
            iconName: "dog.fill",
            colorToken: "orange"
        )
        // Don't insert — this is purely visual
        return TapAndHoldTaskView(
            task: demoTask,
            isCompleted: tutorialCompleted,
            circleSize: 100,
            onSingleTap: {},
            onCompleted: {
                tutorialCompleted = true
            }
        )
        .padding(.vertical, 16)
    }

    // MARK: - Screen 3: First Task Creation

    @State private var showingTaskSelector = false

    private var firstTaskScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("Create Your First Habit")
                .font(.title2.weight(.bold))

            Text("Choose a preset or create a custom habit to get started.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingTaskSelector = true
            } label: {
                Text("Choose a Habit")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.accentColor))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .sheet(isPresented: $showingTaskSelector, onDismiss: {
            // Check if a task was created
            let descriptor = FetchDescriptor<HabitTask>()
            if let count = try? modelContext.fetchCount(descriptor), count > 0 {
                completeOnboarding()
            }
        }) {
            NewTaskSelectorView()
        }
    }

    // MARK: - Helpers

    private func completeOnboarding() {
        let settings = AppSettings.shared(in: modelContext)
        settings.hasCompletedOnboarding = true
        onFinish()
    }
}
