import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    static let customLabelKey = "customLabel"

    private let defaults: UserDefaults

    @Published private(set) var customLabel: String?

    var displayLabel: String {
        customLabel ?? ProcessInfo.processInfo.hostName
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.customLabel = defaults.string(forKey: Self.customLabelKey)
    }

    func setLabel(_ label: String?) {
        let normalized = label?.trimmingCharacters(in: .whitespaces)
        let value = (normalized?.isEmpty ?? true) ? nil : normalized

        customLabel = value
        if let value {
            defaults.set(value, forKey: Self.customLabelKey)
        } else {
            defaults.removeObject(forKey: Self.customLabelKey)
        }
    }

    func resetToHostname() {
        setLabel(nil)
    }
}
