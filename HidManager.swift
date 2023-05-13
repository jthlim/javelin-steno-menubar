import Foundation
import IOKit
import IOKit.usb
import IOKit.hid

protocol HidManagerListener {
    func onDeviceListUpdated(_ devices : [JavelinDevice])
    func onButtonScriptEvent(text : String)
}

class HidManager {
    var manager : IOHIDManager
    var javelinDevices = [JavelinDevice]()
    var listener : HidManagerListener?;
    
    init() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone));

        let javelinFilter : NSDictionary = [kIOHIDDeviceUsagePageKey: 0xFF31, kIOHIDDeviceUsageKey: 0x0074]
        IOHIDManagerSetDeviceMatching(manager, javelinFilter)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, 0)
        
        let matchingCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this = Unmanaged<HidManager>.fromOpaque(inContext!).takeUnretainedValue()
            this.connected(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        
        let removalCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this = Unmanaged<HidManager>.fromOpaque(inContext!).takeUnretainedValue()
            this.removed(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        
        let this = Unmanaged.passRetained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, matchingCallback, this)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, this)
    }
    
    func connected(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        let javelinDevice = JavelinDevice(inIOHIDDeviceRef, listener: listener)
        print("Connected \(javelinDevice)")
        javelinDevices.append(javelinDevice)
        javelinDevice.connect()
        listener?.onDeviceListUpdated(javelinDevices)
    }
    
    func removed(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        print("Device removed")
        javelinDevices.removeAll(where: { $0.device == inIOHIDDeviceRef} )
        listener?.onDeviceListUpdated(javelinDevices)
    }
}

