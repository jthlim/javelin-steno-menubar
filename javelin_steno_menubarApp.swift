import SwiftUI

class MenuBarAppState : ObservableObject, HidManagerListener {
    @Published var devices = [JavelinDevice]()
    @Published var iconName : String = "questionmark"
    
    func onDeviceListUpdated(_ devices: [JavelinDevice]) {
        self.devices = devices
        if devices.isEmpty {
            iconName = "questionmark"
        }
    }
    
    func onButtonScriptEvent(text: String) {
        print("Received Event: \(text)")
        
        switch (text) {
        case "layer: qwerty":
            iconName = "keyboard"
            
        case "layer: steno":
            iconName = "bolt"
            
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
        MenuBarExtra(state.iconName, systemImage: state.iconName) {
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
