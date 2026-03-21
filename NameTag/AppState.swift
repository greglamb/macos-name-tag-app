import Foundation
import Combine

final class AppState: ObservableObject {
    private static let customLabelKey = "customLabel"

    @Published var customLabel: String? {
        didSet {
            if let label = customLabel, label.trimmingCharacters(in: .whitespaces).isEmpty {
                customLabel = nil
                return
            }
            if let customLabel {
                UserDefaults.standard.set(customLabel, forKey: Self.customLabelKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.customLabelKey)
            }
        }
    }

    var displayLabel: String {
        customLabel ?? ProcessInfo.processInfo.hostName
    }

    init() {
        self.customLabel = UserDefaults.standard.string(forKey: Self.customLabelKey)
    }

    func resetToHostname() {
        customLabel = nil
    }
}
