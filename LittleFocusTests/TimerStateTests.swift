import XCTest
@testable import LittleFocus

final class TimerStateTests: XCTestCase {
    func testPauseAndResumePreserveRemainingTime() {
        var state = TimerState()
        let start = Date(timeIntervalSince1970: 1000)
        state.toggle(at: start)
        state.toggle(at: start.addingTimeInterval(30))
        XCTAssertNil(state.deadline)
        XCTAssertEqual(state.remaining, 1470)
        state.toggle(at: start.addingTimeInterval(90))
        XCTAssertEqual(state.deadline, start.addingTimeInterval(1560))
    }
    func testBackgroundCompletionIsCountedExactlyOnceAtDeadline() {
        var state = TimerState()
        let start = Date(timeIntervalSince1970: 1000)
        state.toggle(at: start)
        state.reconcile(at: start.addingTimeInterval(2000))
        state.reconcile(at: start.addingTimeInterval(3000))
        XCTAssertEqual(state.sessions.count, 1)
        XCTAssertEqual(state.sessions.first?.finishedAt, start.addingTimeInterval(1500))
        XCTAssertEqual(state.remaining, 0)
        XCTAssertNil(state.deadline)
    }
    func testRestDoesNotCountAsFocus() {
        var state = TimerState()
        state.select(.rest)
        XCTAssertEqual(state.remaining, 300)
        let start = Date()
        state.toggle(at: start)
        state.reconcile(at: start.addingTimeInterval(301))
        XCTAssertTrue(state.sessions.isEmpty)
    }
    func testResetAndModeSwitchCancelRunningSession() {
        var state = TimerState()
        state.toggle(at: Date())
        state.select(.rest)
        XCTAssertNil(state.deadline)
        XCTAssertEqual(state.remaining, 300)
        state.select(.focus)
        state.reset()
        XCTAssertEqual(state.remaining, 1500)
        XCTAssertTrue(state.sessions.isEmpty)
    }
    func testPersistenceRoundTripKeepsDeadlineTasksAndHistory() throws {
        var state = TimerState()
        state.tasks.append(FocusTask(title: "Read a chapter"))
        state.toggle(at: Date(timeIntervalSince1970: 1000))
        let restored = try JSONDecoder().decode(TimerState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.deadline, state.deadline)
        XCTAssertEqual(restored.tasks.first?.title, "Read a chapter")
    }
}
