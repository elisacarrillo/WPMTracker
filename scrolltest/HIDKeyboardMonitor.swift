import IOKit.hid
import Combine
import Foundation

import Cocoa
class HIDKeyboardMonitor : ObservableObject {
    private var hidManager: IOHIDManager?
    
    private var context: NSManagedObjectContext

    
    @Published var lastKeyPressed: String = "No key yet"
    private static var keyMap: [Int: String] = [
        4: "A", 5: "B", 6: "C", 7: "D", 8: "E", 9: "F", 10: "G",
        11: "H", 12: "I", 13: "J", 14: "K", 15: "L", 16: "M", 17: "N",
        18: "O", 19: "P", 20: "Q", 21: "R", 22: "S", 23: "T", 24: "U",
        25: "V", 26: "W", 27: "X", 28: "Y", 29: "Z",
        30: "1", 31: "2", 32: "3", 33: "4", 34: "5", 35: "6", 36: "7",
        37: "8", 38: "9", 39: "0",
        40: "\n", 41: "e", 42: "b", 43: "t", 44: " ",
        45: "-", 46: "=", 47: "[", 48: "]"
    ]
    private var mainTimer: Timer?
    private var isTracking: Bool = false
    private var minuteTimer: Timer?
    
    private var typedCharactersBuffer: [(char: String, timestamp: Date)] = []

    @Published var currentWPM: Int = 0
    @Published var typedCharacters: String = ""
    
    @Published var inactivityTimer: Timer?
    private var zeroWPMCounter: Int = 0
    private var totalPausedDuration: TimeInterval = 0
//    private var context: NSManagedObjectContext
    @Published var elapsedTimeString: String = "00:00"
    @Published var minuteTimerString: String = "00:00"
    private var startTime: Date?
    var isTrackingPublic: Bool {
        isTracking
    }
    
    private var inactivityElapsedSeconds: Int = 0 // Tracks the elapsed time for inactivity

    private func startInactivityTimer() {
        print("Starting inactivity timer...")
        inactivityElapsedSeconds = 0 // Reset the elapsed time
        
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.inactivityElapsedSeconds += 1 // Increment the elapsed time
            print("Inactivity Timer Elapsed Seconds: \(self.inactivityElapsedSeconds)")

            if self.currentWPM == 0 {
                self.zeroWPMCounter += 1
                print("Consecutive seconds of 0 WPM: \(self.zeroWPMCounter)")
                
                // Check both zero WPM counter and elapsed time
                if self.zeroWPMCounter >= 3 && self.inactivityElapsedSeconds > 5 {
                    print("Pausing due to inactivity...")
                    self.pause()
                }
            } else {
                self.zeroWPMCounter = 0 // Reset counter if WPM is non-zero
            }
        }
    }

    func isTrackingSet(bvar: Bool) {
        
        
        
        if !isTracking && bvar {
            startInactivityTimer()
            startTimer()
            startMinuteTimer()
            startTime = Date() // Set startTime when tracking starts
//            calculateWPM()
        } else if (isTracking && !bvar) {
            stopMinuteTimer()
        }
        self.isTracking = bvar
        
    }
    func isTrackingGet() -> Bool {
        
        return isTracking
    }
    
    func isElapTimeStringSet(strang:String) {
        self.elapsedTimeString = strang
    }
    
    
    init(context: NSManagedObjectContext) {
        self.context = context
        setupHIDManager()
    
        
    }
    
//    private func setupHIDManager() {
//        // Create the HID Manager
//        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
//        hidManager = manager // Assign to the class property
//        print("IOHIDManager created successfully.")
//        
//        // Set the device matching criteria for keyboards
//        let matchingDict: [String: Any] = [
//            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
//            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Keyboard
//        ]
//        IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)
//        
//        // Register the static callback
//        IOHIDManagerRegisterInputValueCallback(manager, Self.inputCallback, Unmanaged.passUnretained(self).toOpaque())
//        
//        // Schedule the manager with the current run loop
//        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
//        
//        // Open the HID Manager
//        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
//        if result == kIOReturnSuccess {
//            print("HID Manager successfully opened.")
//        } else {
//            print("Failed to open HID Manager: \(result)")
//            self.elapsedTimeString="Error with permissions :("
//        }
//    }
//    
//    import Foundation
//    import IOKit.hid

    private func setupHIDManager() {
        // Check for Input Monitoring permission
        let accessStatus = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)

        switch accessStatus {
        case IOHIDAccessType(rawValue: 0): // kIOHIDAccessTypeGranted
            print("Input Monitoring access granted.")
        case IOHIDAccessType(rawValue: 1): // kIOHIDAccessTypeDenied
            print("Input Monitoring access denied.")
            self.elapsedTimeString = "Error: Input Monitoring denied."

            // Inform the user with a dialog and guide them to enable the permission manually
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Input Monitoring Access Denied"
                alert.informativeText = """
                Input Monitoring is required for this app to function properly.
                Please enable it in System Preferences > Security & Privacy > Input Monitoring.
                """
                alert.alertStyle = .critical
                alert.addButton(withTitle: "Open System Preferences")
                alert.addButton(withTitle: "Cancel")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    // Open System Preferences to the Input Monitoring section
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                        NSWorkspace.shared.open(url)
                    }
                }

            }
            return

        case IOHIDAccessType(rawValue: 2): // kIOHIDAccessTypeUnknown
            print("Input Monitoring status unknown. Requesting access...")
            if !IOHIDRequestAccess(kIOHIDRequestTypeListenEvent) {
                print("Input Monitoring access request denied.")
                self.elapsedTimeString = "Error: Input Monitoring not granted."
                return
            }
            print("Input Monitoring access granted after request.")
        default:
            print("Unexpected Input Monitoring access status.")
            self.elapsedTimeString = "Error: Unexpected access status."
            return
        }
//        let accessStatus = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
//
//        if accessStatus == IOHIDAccessType(rawValue: 1) { // kIOHIDAccessTypeDenied
//            print("Input Monitoring access was denied.")
//            DispatchQueue.main.async {
//                let alert = NSAlert()
//                alert.messageText = "Input Monitoring Required"
//                alert.informativeText = "Please enable Input Monitoring for this app in System Preferences > Privacy & Security > Input Monitoring."
//                alert.alertStyle = .warning
//                alert.addButton(withTitle: "Open System Preferences")
//                alert.addButton(withTitle: "Cancel")
//                let response = alert.runModal()
//                
//                if response == .alertFirstButtonReturn {
//                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
//                        NSWorkspace.shared.open(url)
//                    }
//                }
//            }
//            return
//        }


        // Create the HID Manager
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        if CFGetTypeID(manager) != IOHIDManagerGetTypeID() {
            print("Failed to create a valid IOHIDManager.")
            self.elapsedTimeString = "Error: Invalid IOHIDManager."
            return
        }
        hidManager = manager // Assign to the class property
        print("IOHIDManager created successfully.")
        
        // Set the device matching criteria for keyboards
        let matchingDict: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Keyboard
        ]
        IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)

        // Register the static callback
        IOHIDManagerRegisterInputValueCallback(manager, Self.inputCallback, Unmanaged.passUnretained(self).toOpaque())

        // Schedule the manager with the current run loop
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

        // Open the HID Manager
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result == kIOReturnSuccess {
            print("HID Manager successfully opened.")
        } else {
            print("Failed to open HID Manager: \(result)")
            self.elapsedTimeString = "Error with permissions or HID Manager initialization."
        }
    }

    
    
    
    func calculateWPM(for elapsedTimeInSeconds: Double = 10.0) -> Int {
        // Ensure elapsed time is valid
        guard elapsedTimeInSeconds > 0 else {
            print("Invalid elapsed time. Returning WPM as 0.")
            return 0
        }

        // Split `typedCharacters` into words based on spaces and enters
        let words = typedCharacters.split { $0 == " " || $0 == "\n" }.count - 1

        // Calculate WPM
        let elapsedTimeInMinutes = elapsedTimeInSeconds / 60.0
        let calculatedWPM = elapsedTimeInMinutes > 0 ? Int(Double(words) / elapsedTimeInMinutes) : 0

        print("Elapsed time: \(elapsedTimeInSeconds) seconds, Words: \(words), Calculated WPM: \(calculatedWPM)")
        return calculatedWPM
    }


    

    
   
    
    
    /// Starts the minute timer and updates `minuteTimerString` with elapsed time.
    private func startMinuteTimer() {
        guard minuteTimer == nil else {
            print("Minute timer already running. Skipping creation.")
            return
        }
//        startInactivityTimer()
        let totalDuration: TimeInterval = 10 // Total duration of 10 seconds
        var elapsedTime: TimeInterval = 0 // Track elapsed time

        print("Starting minute timer at \(Date())")
        minuteTimerString = "00:00" // Reset at the start

        // Timer ticks every second
        minuteTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Increment elapsed time
            elapsedTime += 1

            // Update `minuteTimerString` with elapsed seconds
            let seconds = Int(elapsedTime) % 60 // Only track seconds (0-59)
            DispatchQueue.main.async {
                self.minuteTimerString = String(format: "00:%02d", seconds)
                self.updateDynamicWPM()
                print("Updated minuteTimerString: \(self.minuteTimerString)")
            }
            
            // Trigger WPM update and reset after 10 seconds
            if elapsedTime >= totalDuration {
//                self.updateAndResetWPM()
                saveCurrentWPM()
//                calculateWPM(10)
                updateDynamicWPM()
                typedCharacters = ""
                elapsedTime = 0 // Reset elapsed time
                
            }
        }
    }

    

    /// Starts the total timer and updates `elapsedTimeString` for each second.
    private func startTimer() {
        guard mainTimer == nil else {
            print("Main timer already running. Skipping creation.")
            return
        }

        var totalElapsedTime: TimeInterval = 0 // Tracks total time

        print("Starting total timer at \(Date())")
        elapsedTimeString = "00:00:00" // Reset total timer display

        mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            totalElapsedTime += 1

            // Update total elapsed time (HH:MM:SS format)
            let hours = Int(totalElapsedTime) / 3600
            let minutes = (Int(totalElapsedTime) % 3600) / 60
            let seconds = Int(totalElapsedTime) % 60

            DispatchQueue.main.async {
                self.elapsedTimeString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                print("Updated elapsedTimeString: \(self.elapsedTimeString)")
            }
        }
    }
    private func stopMinuteTimer() {
        print("Stopping minute timer at \(Date())")
        minuteTimer?.invalidate()
        minuteTimer = nil
    }

    /// Stops and invalidates the total timer.
    private func stopTimer() {
        print("Stopping total timer at \(Date())")
        mainTimer?.invalidate()
        mainTimer = nil
    }
    
//    private func startInactivityTimer() {
//        print("Starting inactivity timer...")
//        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
//            if self.typedCharacters.isEmpty {
//                print("No activity detected. Pausing tracking...")
//                self.pause()
//            }
//        }
//    }

    private func resetInactivityTimer() {
        print("Resetting inactivity timer...")
        inactivityTimer?.invalidate()
        if isTracking {
            startInactivityTimer() // Restart only if tracking is active
        }
    }


    
    private func updateTypedCharacters() {
        let now = Date()
        typedCharactersBuffer = typedCharactersBuffer.filter { now.timeIntervalSince($0.timestamp) <= 10 }
        typedCharacters = typedCharactersBuffer.map { $0.char }.joined()
    }


    private func saveCurrentWPM() {
        print("SAVING WPM + \(isTracking)")
        guard isTracking else { return }
        print("SAVING WPM + \(currentWPM)")
        saveWPMEntry(timestamp: Date(), userId: "defaultUser", wpm: currentWPM, context: context)
    }
    func pause() {
        guard isTracking else {
            print("Tracking is already paused.")
            return
        }
        print("Pausing tracking...")
        isTracking = false
        stopMinuteTimer()
        inactivityTimer?.invalidate()
        zeroWPMCounter = 0 // Reset zero WPM counter
    }

    func resume() {
        guard !isTracking else {
            print("Tracking is already active.")
            return
        }
        print("Resuming tracking...")
        isTracking = true
        zeroWPMCounter = 0 // Reset zero WPM counter
        startMinuteTimer() // Restart the minute timer
        startInactivityTimer() // Restart the inactivity timer
    }

    private func updateDynamicWPM() {
        print("CURRENT WPM: \(currentWPM)")
        guard isTracking else {
            print("updateDynamicWPM skipped: Tracking is paused.")
            return
        }

        // Get the current time
        let now = Date()

        // Prune the buffer to include only the last 10 seconds
        typedCharactersBuffer = typedCharactersBuffer.filter { now.timeIntervalSince($0.timestamp) <= 10 }

        // Count words based on spaces and enters in the last 10 seconds
        let words = typedCharactersBuffer
            .map { $0.char }
            .joined()
            .split { $0 == " " || $0 == "\n" }
            .count

        // Calculate WPM dynamically
        let elapsedTimeInMinutes = 10.0 / 60.0 // Fixed interval of 10 seconds
        let calculatedWPM = Int(Double(words) / elapsedTimeInMinutes)

        // Update `currentWPM` and log the result
        DispatchQueue.main.async {
            self.currentWPM = calculatedWPM
            print("Dynamic WPM updated: \(calculatedWPM) (Words: \(words))")
        }
    }


    private static let inputCallback: IOHIDValueCallback = { context, result, sender, value in
        let element = IOHIDValueGetElement(value)
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)

        // Retrieve the instance of HIDKeyboardMonitor from the context
        let monitor = Unmanaged<HIDKeyboardMonitor>.fromOpaque(context!).takeUnretainedValue()

        // Check if it's a keyboard key event
        if usagePage == kHIDPage_KeyboardOrKeypad {
            if let key = keyMap[Int(usage)] {
                print("Key Pressed: \(key)")
                
                DispatchQueue.main.async {
                    monitor.isTrackingSet(bvar: true)
                    let now = Date()

                    // Add key to buffer with timestamp
                    monitor.typedCharactersBuffer.append((char: key, timestamp: now))
                    monitor.lastKeyPressed = key

                    print("Updated buffer: \(monitor.typedCharactersBuffer.map { $0.char }.joined())")
                }
            } else {
                print("Key Pressed: Unknown (Usage \(usage))")
            }
        }
    }


    
    
}
