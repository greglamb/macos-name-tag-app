import XCTest
import Combine
@testable import NameTag

final class AppStateTests: XCTestCase {
    private var defaults: UserDefaults!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "com.nametag.tests")!
        defaults.removePersistentDomain(forName: "com.nametag.tests")
        cancellables = []
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "com.nametag.tests")
        defaults = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testDefaultStateUsesHostname() {
        let state = AppState(defaults: defaults)

        XCTAssertNil(state.customLabel)
        XCTAssertEqual(state.displayLabel, ProcessInfo.processInfo.hostName)
    }

    func testInitLoadsExistingCustomLabel() {
        defaults.set("My Mac", forKey: AppState.customLabelKey)

        let state = AppState(defaults: defaults)

        XCTAssertEqual(state.customLabel, "My Mac")
        XCTAssertEqual(state.displayLabel, "My Mac")
    }

    // MARK: - Setting Custom Label

    func testSetCustomLabelUpdatesDisplayLabel() {
        let state = AppState(defaults: defaults)

        state.customLabel = "Work Laptop"

        XCTAssertEqual(state.displayLabel, "Work Laptop")
    }

    func testSetCustomLabelPersistsToDefaults() {
        let state = AppState(defaults: defaults)

        state.customLabel = "Office Mac"

        XCTAssertEqual(defaults.string(forKey: AppState.customLabelKey), "Office Mac")
    }

    func testChangeCustomLabelUpdatesDefaults() {
        let state = AppState(defaults: defaults)

        state.customLabel = "First"
        state.customLabel = "Second"

        XCTAssertEqual(defaults.string(forKey: AppState.customLabelKey), "Second")
        XCTAssertEqual(state.displayLabel, "Second")
    }

    // MARK: - Reset to Hostname

    func testResetToHostnameClearsCustomLabel() {
        let state = AppState(defaults: defaults)
        state.customLabel = "Custom"

        state.resetToHostname()

        XCTAssertNil(state.customLabel)
        XCTAssertEqual(state.displayLabel, ProcessInfo.processInfo.hostName)
    }

    func testResetToHostnameRemovesFromDefaults() {
        let state = AppState(defaults: defaults)
        state.customLabel = "Custom"

        state.resetToHostname()

        XCTAssertNil(defaults.string(forKey: AppState.customLabelKey))
    }

    // MARK: - Empty String Handling

    func testEmptyStringNormalizesToNil() {
        let state = AppState(defaults: defaults)

        state.customLabel = ""

        XCTAssertNil(state.customLabel)
        XCTAssertEqual(state.displayLabel, ProcessInfo.processInfo.hostName)
    }

    func testWhitespaceOnlyStringNormalizesToNil() {
        let state = AppState(defaults: defaults)

        state.customLabel = "   "

        XCTAssertNil(state.customLabel)
        XCTAssertEqual(state.displayLabel, ProcessInfo.processInfo.hostName)
    }

    func testEmptyStringRemovesFromDefaults() {
        let state = AppState(defaults: defaults)
        state.customLabel = "Was Set"

        state.customLabel = ""

        XCTAssertNil(defaults.string(forKey: AppState.customLabelKey))
    }

    // MARK: - Combine Publishing

    func testCustomLabelPublishesChanges() {
        let state = AppState(defaults: defaults)
        var receivedValues: [String?] = []

        state.$customLabel
            .dropFirst() // skip initial value
            .sink { receivedValues.append($0) }
            .store(in: &cancellables)

        state.customLabel = "Test"

        XCTAssertEqual(receivedValues, ["Test"])
    }

    func testResetToHostnamePublishesNil() {
        let state = AppState(defaults: defaults)
        state.customLabel = "Before"
        var receivedValues: [String?] = []

        state.$customLabel
            .dropFirst()
            .sink { receivedValues.append($0) }
            .store(in: &cancellables)

        state.resetToHostname()

        XCTAssertEqual(receivedValues, [nil])
    }

    // MARK: - Persistence Round-Trip

    func testPersistenceRoundTrip() {
        let state1 = AppState(defaults: defaults)
        state1.customLabel = "Persisted Label"

        let state2 = AppState(defaults: defaults)

        XCTAssertEqual(state2.customLabel, "Persisted Label")
        XCTAssertEqual(state2.displayLabel, "Persisted Label")
    }

    func testPersistenceRoundTripAfterReset() {
        let state1 = AppState(defaults: defaults)
        state1.customLabel = "Temp"
        state1.resetToHostname()

        let state2 = AppState(defaults: defaults)

        XCTAssertNil(state2.customLabel)
        XCTAssertEqual(state2.displayLabel, ProcessInfo.processInfo.hostName)
    }
}
