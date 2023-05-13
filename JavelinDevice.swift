import Foundation
import IOKit
import IOKit.usb
import IOKit.hid

class JavelinDevice : NSObject {
    var device : IOHIDDevice
    var inputBuffer = Data()
    var lastByte : UInt8 = 0
    var listener : HidManagerListener?;
    
    init(_ device: IOHIDDevice, listener : HidManagerListener?) {
        self.listener = listener
        self.device = device
    }
    
    func getProductName() -> String {
        return IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? ""
    }
    
    static func == (lhs: JavelinDevice, rhs: JavelinDevice) -> Bool {
        lhs.device == rhs.device
    }
    
    func input(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {
        
        for i in 0 ..< reportLength {
            var byte = report[i]
            if byte == 0 {
                continue
            }
            inputBuffer.append(&byte, count: 1)
            if byte == 10 && lastByte == 10 {
                processData()
                inputBuffer.removeAll()
                byte = 0;
            }
            lastByte = byte
        }        
    }
    
    func processData() {
        // Convert data to utf8
        let message = String(decoding: inputBuffer, as: UTF8.self)
        
        // Only proceed if it's an event.
        if !message.starts(with: "EV") {
            return
        }
        
        // Decode to json
        let jsonText = message[message.index(message.startIndex, offsetBy: 3)...]
        let json = try! JSONSerialization.jsonObject(with: jsonText.data(using: .utf8)!) as? [String: AnyObject]
        guard let json = json else {
            return
        }
        
        // Check if it's a button script event.
        if json["event"] as? String != "button_script_event" {
            return
        }
        
        guard let text = json["text"] as? String else {
            return;
        }
        
        listener?.onButtonScriptEvent(text: text)
    }
    
    func connect() {
        IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        let reportSize = 64
        let report = UnsafeMutablePointer<UInt8>.allocate(capacity: reportSize)

        let inputCallback : IOHIDReportCallback = { inContext, inResult, inSender, type, reportId, report, reportLength in
            let this = Unmanaged<JavelinDevice>.fromOpaque(inContext!).takeUnretainedValue()
            this.input(inResult, inSender: inSender!, type: type, reportId: reportId, report: report, reportLength: reportLength)
        }
        
        let this = Unmanaged.passRetained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device, report, reportSize, inputCallback, this)
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: JavelinDevice) {
        appendInterpolation("Javelin Device: \(value.getProductName())");
    }
}

