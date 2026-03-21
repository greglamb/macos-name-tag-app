import SwiftUI

struct OptionsView: View {
    @ObservedObject var appState: AppState
    var onDismiss: () -> Void

    @State private var labelText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Display Label:")
                .font(.headline)

            TextField("Enter label", text: $labelText)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Hostname") {
                    appState.resetToHostname()
                    onDismiss()
                }

                Spacer()

                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    appState.customLabel = labelText
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 350)
        .onAppear {
            labelText = appState.displayLabel
        }
    }
}
