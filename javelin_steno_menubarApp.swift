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
    
    func onButtonScriptEvent(text: String) {
        print("Received Event: \(text)")
        
        switch (text) {
        case "layer: qwerty":
            iconName = "QWERTY"
            
        case "layer: steno":
            iconName = "Steno"
            
        default:
            break;
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
