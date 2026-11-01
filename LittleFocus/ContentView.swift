import SwiftUI
import Combine

private let ink = Color(red: 0.09, green: 0.17, blue: 0.14)
private let leaf = Color(red: 0.80, green: 0.90, blue: 0.64)

struct ContentView: View {
    @EnvironmentObject private var model: FocusModel
    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    var body: some View {
        TabView {
            FocusView().tabItem { Label("Focus", systemImage: "leaf") }
            HistoryView().tabItem { Label("History", systemImage: "chart.bar") }
            SettingsView().tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .onReceive(ticker) { model.tick(at: $0) }
        .alert("Storage", isPresented: Binding(get: { model.storageMessage != nil }, set: { if !$0 { model.storageMessage = nil } })) {
            Button("OK") { model.storageMessage = nil }
        } message: { Text(model.storageMessage ?? "") }
    }
}

struct FocusView: View {
    @EnvironmentObject private var model: FocusModel
    @State private var taskTitle = ""
    @FocusState private var editing: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack {
                        Label("little focus", systemImage: "sparkle").font(.headline)
                        Spacer()
                        Text(Date(), format: .dateTime.month(.abbreviated).day()).font(.subheadline).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("A LITTLE SPACE FOR YOU").font(.caption).tracking(2).foregroundStyle(leaf)
                        Text("One thing.\nAll your attention.").font(.system(.largeTitle, design: .serif))
                        Text("Make room for what matters. The rest can wait a little.").foregroundStyle(.secondary)
                    }
                    Picker("Timer mode", selection: Binding(get: { model.state.mode }, set: { model.select($0) })) {
                        ForEach(FocusMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    ZStack {
                        Circle().stroke(leaf.opacity(0.15), lineWidth: 4)
                        Circle().trim(from: 0, to: min(1, max(0, model.state.remaining / model.state.duration)))
                            .stroke(leaf, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90))
                        VStack(spacing: 10) {
                            Text(model.timeText).font(.system(size: 60, weight: .light, design: .rounded)).monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                            Text(model.state.remaining == 0 ? "BEAUTIFULLY DONE" : model.state.mode == .focus ? "FIND YOUR FLOW" : "LET YOURSELF REST").font(.caption2).tracking(2)
                        }.padding(20)
                    }
                    .frame(maxWidth: 290).aspectRatio(1, contentMode: .fit).frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore).accessibilityLabel("Time remaining").accessibilityValue(model.timeText)
                    HStack {
                        Button { editing = false; model.toggle() } label: {
                            Label(model.state.deadline != nil ? "Pause" : model.state.remaining == 0 ? "Start again" : "Start session", systemImage: model.state.deadline != nil ? "pause.fill" : "play.fill")
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                        }.buttonStyle(.borderedProminent).foregroundStyle(ink)
                        Button("Reset") { model.reset() }.buttonStyle(.bordered).padding(.vertical, 8)
                    }.controlSize(.large)
                    Divider()
                    Text("What's your one thing?").font(.headline)
                    HStack {
                        TextField("Give your attention a direction…", text: $taskTitle).focused($editing).submitLabel(.done).onSubmit(addTask)
                        Button(action: addTask) { Image(systemName: "plus.circle.fill").font(.title) }
                            .frame(minWidth: 44, minHeight: 44).accessibilityLabel("Add task")
                            .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }.padding(12).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                    if model.state.tasks.isEmpty { Text("A small step is a good place to start.").foregroundStyle(.secondary) }
                    ForEach(model.state.tasks) { task in
                        HStack {
                            Button { model.toggleTask(task.id) } label: {
                                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle").font(.title2).frame(width: 44, height: 44)
                            }.accessibilityLabel(task.completed ? "Mark incomplete" : "Complete task")
                            Text(task.title).strikethrough(task.completed).foregroundStyle(task.completed ? .secondary : .primary)
                            Spacer()
                            Button(role: .destructive) { model.deleteTask(task.id) } label: { Image(systemName: "trash").frame(width: 44, height: 44) }.accessibilityLabel("Delete \(task.title)")
                        }
                    }
                    HStack {
                        VStack(alignment: .leading) { Text("Today's quiet wins").font(.headline); Text("Completed focus sessions").font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        Text("\(model.todaySessions.count)").font(.system(.largeTitle, design: .serif)).foregroundStyle(leaf)
                    }
                    Text("Less noise. More you.").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }.padding(24)
            }
            .background(LinearGradient(colors: [Color(red: 0.17, green: 0.27, blue: 0.20), ink], startPoint: .top, endPoint: .bottom))
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    private func addTask() { model.addTask(taskTitle); taskTitle = ""; editing = false }
}

struct HistoryView: View {
    @EnvironmentObject private var model: FocusModel
    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    LabeledContent("Sessions", value: "\(model.todaySessions.count)")
                    LabeledContent("Focused minutes", value: "\(model.todaySessions.reduce(0) { $0 + $1.minutes })")
                }
                Section("Completed sessions") {
                    if model.state.sessions.isEmpty { Text("Your first quiet win starts with one session.").foregroundStyle(.secondary) }
                    ForEach(model.state.sessions) { session in
                        HStack {
                            Image(systemName: "leaf.fill").foregroundStyle(leaf)
                            VStack(alignment: .leading) {
                                Text("\(session.minutes) minutes of focus")
                                Text(session.finishedAt, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }.navigationTitle("Quiet wins")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var model: FocusModel
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Focus: \(model.state.focusMinutes) min", value: Binding(get: { model.state.focusMinutes }, set: { model.setMinutes(focus: $0, rest: model.state.restMinutes) }), in: 1...90)
                    Stepper("Rest: \(model.state.restMinutes) min", value: Binding(get: { model.state.restMinutes }, set: { model.setMinutes(focus: model.state.focusMinutes, rest: $0) }), in: 1...30)
                } header: { Text("Your rhythm") } footer: { Text("Changing a duration resets the current timer.") }
                Section("On your device") {
                    Text("Tasks and session history stay on this iPhone. No account, ads, or analytics.")
                    Text("The timer catches up when you return to the app. This version does not send background alerts.").foregroundStyle(.secondary)
                }
                Section { LabeledContent("Little Focus", value: "1.0") }
            }.navigationTitle("Settings")
        }
    }
}
