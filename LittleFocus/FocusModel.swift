import Foundation
import Combine

struct FocusTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var completed = false
}

struct FocusSession: Identifiable, Codable {
    var id = UUID()
    var finishedAt: Date
    var minutes: Int
}

enum FocusMode: String, Codable, CaseIterable {
    case focus = "Focus", rest = "Rest"
}

struct TimerState: Codable {
    var tasks: [FocusTask] = []
    var sessions: [FocusSession] = []
    var focusMinutes = 25
    var restMinutes = 5
    var mode: FocusMode = .focus
    var remaining: TimeInterval = 25 * 60
    var deadline: Date?
    var duration: TimeInterval { TimeInterval((mode == .focus ? focusMinutes : restMinutes) * 60) }

    mutating func reconcile(at now: Date) {
        guard let deadline else { return }
        remaining = max(0, deadline.timeIntervalSince(now))
        if remaining == 0 {
            if mode == .focus {
                sessions.insert(FocusSession(finishedAt: deadline, minutes: focusMinutes), at: 0)
            }
            self.deadline = nil
        }
    }

    mutating func toggle(at now: Date) {
        reconcile(at: now)
        if deadline != nil {
            deadline = nil
        } else {
            if remaining <= 0 { remaining = duration }
            deadline = now.addingTimeInterval(remaining)
        }
    }

    mutating func reset() { deadline = nil; remaining = duration }
    mutating func select(_ mode: FocusMode) { self.mode = mode; reset() }
}

@MainActor
final class FocusModel: ObservableObject {
    @Published private(set) var state: TimerState
    @Published var storageMessage: String?
    private let defaults: UserDefaults
    private let key = "LittleFocus.Native.State.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key) {
            do { state = try JSONDecoder().decode(TimerState.self, from: data) }
            catch { state = TimerState(); storageMessage = "Saved progress could not be read. A new session is ready." }
        } else { state = TimerState() }
        tick()
    }

    func save() {
        do { defaults.set(try JSONEncoder().encode(state), forKey: key) }
        catch { storageMessage = "Progress could not be saved." }
    }
    func tick(at now: Date = Date()) {
        let wasRunning = state.deadline != nil
        state.reconcile(at: now)
        if wasRunning && state.deadline == nil { save() }
    }
    func toggle() { state.toggle(at: Date()); save() }
    func reset() { tick(); state.reset(); save() }
    func select(_ mode: FocusMode) { tick(); state.select(mode); save() }
    func addTask(_ title: String) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        state.tasks.append(FocusTask(title: String(clean.prefix(160)))); save()
    }
    func toggleTask(_ id: UUID) {
        guard let index = state.tasks.firstIndex(where: { $0.id == id }) else { return }
        state.tasks[index].completed.toggle(); save()
    }
    func deleteTask(_ id: UUID) { state.tasks.removeAll { $0.id == id }; save() }
    func setMinutes(focus: Int, rest: Int) {
        tick()
        state.focusMinutes = min(90, max(1, focus))
        state.restMinutes = min(30, max(1, rest))
        state.reset(); save()
    }
    var todaySessions: [FocusSession] {
        state.sessions.filter { Calendar.current.isDateInToday($0.finishedAt) }
    }
    var timeText: String {
        let seconds = Int(ceil(state.remaining))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
