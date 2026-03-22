import Foundation
import Testing
import Combine
@testable import NameTag

@MainActor
struct AppStateTests {
    private let defaults: UserDefaults
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let suite = "suite-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    // MARK: - Initial State

    @Test func defaultStateUsesHostname() {
        let state = AppState(defaults: defaults)

        #expect(state.customLabel == nil)
        #expect(state.displayLabel == AppState.hostname)
    }

    @Test func initLoadsExistingCustomLabel() {
        defaults.set("My Mac", forKey: AppState.customLabelKey)

        let state = AppState(defaults: defaults)

        #expect(state.customLabel == "My Mac")
        #expect(state.displayLabel == "My Mac")
    }

    // MARK: - Setting Custom Label

    @Test func setCustomLabelUpdatesDisplayLabel() {
        let state = AppState(defaults: defaults)

        state.setLabel("Work Laptop")

        #expect(state.displayLabel == "Work Laptop")
    }

    @Test func setCustomLabelPersistsToDefaults() {
        let state = AppState(defaults: defaults)

        state.setLabel("Office Mac")

        #expect(defaults.string(forKey: AppState.customLabelKey) == "Office Mac")
    }

    @Test func changeCustomLabelUpdatesDefaults() {
        let state = AppState(defaults: defaults)

        state.setLabel("First")
        state.setLabel("Second")

        #expect(defaults.string(forKey: AppState.customLabelKey) == "Second")
        #expect(state.displayLabel == "Second")
    }

    // MARK: - Reset to Hostname

    @Test func resetToHostnameClearsCustomLabel() {
        let state = AppState(defaults: defaults)
        state.setLabel("Custom")

        state.resetToHostname()

        #expect(state.customLabel == nil)
        #expect(state.displayLabel == AppState.hostname)
    }

    @Test func resetToHostnameRemovesFromDefaults() {
        let state = AppState(defaults: defaults)
        state.setLabel("Custom")

        state.resetToHostname()

        #expect(defaults.string(forKey: AppState.customLabelKey) == nil)
    }

    // MARK: - Empty String Handling

    @Test(arguments: ["", "   ", "\t", "\n"])
    func blankStringNormalizesToNil(input: String) {
        let state = AppState(defaults: defaults)

        state.setLabel(input)

        #expect(state.customLabel == nil)
        #expect(state.displayLabel == AppState.hostname)
    }

    @Test func blankStringRemovesFromDefaults() {
        let state = AppState(defaults: defaults)
        state.setLabel("Was Set")

        state.setLabel("")

        #expect(defaults.string(forKey: AppState.customLabelKey) == nil)
    }

    // MARK: - Combine Publishing

    @Test mutating func customLabelPublishesChanges() {
        let state = AppState(defaults: defaults)
        var receivedValues: [String?] = []

        state.$customLabel
            .dropFirst()
            .sink { receivedValues.append($0) }
            .store(in: &cancellables)

        state.setLabel("Test")

        #expect(receivedValues == ["Test"])
    }

    @Test mutating func resetToHostnamePublishesNil() {
        let state = AppState(defaults: defaults)
        state.setLabel("Before")
        var receivedValues: [String?] = []

        state.$customLabel
            .dropFirst()
            .sink { receivedValues.append($0) }
            .store(in: &cancellables)

        state.resetToHostname()

        #expect(receivedValues == [nil])
    }

    // MARK: - Persistence Round-Trip

    @Test func persistenceRoundTrip() {
        let state1 = AppState(defaults: defaults)
        state1.setLabel("Persisted Label")

        let state2 = AppState(defaults: defaults)

        #expect(state2.customLabel == "Persisted Label")
        #expect(state2.displayLabel == "Persisted Label")
    }

    @Test func persistenceRoundTripAfterReset() {
        let state1 = AppState(defaults: defaults)
        state1.setLabel("Temp")
        state1.resetToHostname()

        let state2 = AppState(defaults: defaults)

        #expect(state2.customLabel == nil)
        #expect(state2.displayLabel == AppState.hostname)
    }
}
