import Cocoa
import Combine


class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    var keyboardTracker: HIDKeyboardMonitor?
    private var cancellable: AnyCancellable?
    private var isPaused: Bool = true // Tracks whether tracking is paused

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Core Data persistent container and context
        let persistentContainer = PreviewPersistentContainer.shared
        let context = persistentContainer.viewContext
        
        // Initialize the keyboard tracker
        keyboardTracker = HIDKeyboardMonitor(context: context)
        
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Configure the status bar button
        if let button = statusItem?.button {
            button.title = "0 WPM" // Initial title
        }
        
        // Subscribe to WPM updates from the keyboard tracker
        cancellable = keyboardTracker?.$currentWPM
            .receive(on: RunLoop.main)
            .sink { [weak self] newWPM in
                self?.statusItem?.button?.title = "\(newWPM) WPM"
            }
        
        // Set up the menu
        configureMenu()
        
        print("Application finished launching.")
    }

    /// Configures the menu for the status bar item
    private func configureMenu() {
        let menu = NSMenu()
        print("Menu configured.")
        
        // Add a menu item for Quit
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Assign the menu to the status item
        statusItem?.menu = menu
    }

    /// Toggles between Pause and Resume
    @objc private func togglePause() {
        isPaused.toggle()
        if isPaused {
            keyboardTracker?.pause()
            print("Tracking paused.")
        } else {
            keyboardTracker?.resume()
            print("Tracking resumed.")
        }
        configureMenu() // Update menu title dynamically
    }

    /// Quits the application
    @objc private func quitApp() {
        print("Quitting application...")
        NSApplication.shared.terminate(self)
    }
}
