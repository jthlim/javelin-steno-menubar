import SwiftUI

class MenuBarAppState : ObservableObject, HidManagerListener {
    @Published var devices = [JavelinDevice]()
    @Published var iconName : String = "Unknown"

    func onDeviceListUpdated(_ devices: [JavelinDevice]) {
        self.devices = devices
        if devices.isEmpty {
            iconName = "Unknown"
        }
    }

    func onScriptEvent(text: String) {
        // print("Received Event: \(text)")

        switch (text.localizedLowercase) {
        case "layer_id: 1128808786":
            iconName = "QWERTY"

        case "layer_id: 87377230":
            iconName = "Steno"

        default:
            break
        }
    }
}

@main
struct javelin_steno_menubarApp: App {
    @ObservedObject var state = MenuBarAppState()
    var hidManager = HidManager()

    init() {
        hidManager.listener = state
    }

    var body: some Scene {
        MenuBarExtra(state.iconName, image: state.iconName) {
            ForEach(state.devices, id: \.self) { device in
                Button(device.getProductName()) {
                }
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(self)
            }.keyboardShortcut("Q", modifiers: [.command])
        }
    }
}
