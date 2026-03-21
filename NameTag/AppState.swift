import Foundation
import Combine

final class AppState: ObservableObject {
    static let customLabelKey = "customLabel"

    private let defaults: UserDefaults

    @Published var customLabel: String? {
        didSet {
            if let label = customLabel, label.trimmingCharacters(in: .whitespaces).isEmpty {
                customLabel = nil
                return
            }
            if let customLabel {
                defaults.set(customLabel, forKey: Self.customLabelKey)
            } else {
                defaults.removeObject(forKey: Self.customLabelKey)
            }
        }
    }

    var displayLabel: String {
        customLabel ?? ProcessInfo.processInfo.hostName
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.customLabel = defaults.string(forKey: Self.customLabelKey)
    }

    func resetToHostname() {
        customLabel = nil
    }
}
