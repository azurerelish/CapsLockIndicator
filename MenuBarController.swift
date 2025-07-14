import Cocoa

class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var capsLockMenuItem: NSMenuItem!
    private var showCapsLockHUDMenuItem: NSMenuItem!
    private var showLanguageHUDMenuItem: NSMenuItem!
    
    // User preferences for which HUDs to show
    var showCapsLockHUD: Bool = true {
        didSet {
            updateHUDMenuItems()
            UserDefaults.standard.set(showCapsLockHUD, forKey: "ShowCapsLockHUD")
        }
    }
    
    var showLanguageHUD: Bool = true {
        didSet {
            updateHUDMenuItems()
            UserDefaults.standard.set(showLanguageHUD, forKey: "ShowLanguageHUD")
        }
    }
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        super.init()
        loadPreferences()
        setupMenuBar()
        updateHUDMenuItems() // Update menu items after everything is set up
    }
    
    private func loadPreferences() {
        // Load saved preferences, default to true if not set
        showCapsLockHUD = UserDefaults.standard.object(forKey: "ShowCapsLockHUD") as? Bool ?? true
        showLanguageHUD = UserDefaults.standard.object(forKey: "ShowLanguageHUD") as? Bool ?? true
    }
    
    private func updateHUDMenuItems() {
        // Safely update menu items only if they exist
        showCapsLockHUDMenuItem?.state = showCapsLockHUD ? .on : .off
        showLanguageHUDMenuItem?.state = showLanguageHUD ? .on : .off
    }
    
    private func setupMenuBar() {
        // Set initial icon
        updateIcon(capsLockEnabled: false)
        
        // Create status display item
        capsLockMenuItem = NSMenuItem(title: "Caps Lock: OFF", action: nil, keyEquivalent: "")
        capsLockMenuItem.isEnabled = false
        menu.addItem(capsLockMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Create HUD preference menu items with checkboxes
        showCapsLockHUDMenuItem = NSMenuItem(
            title: "Show Caps Lock HUD",
            action: #selector(toggleCapsLockHUD),
            keyEquivalent: ""
        )
        showCapsLockHUDMenuItem.target = self
        menu.addItem(showCapsLockHUDMenuItem)
        
        showLanguageHUDMenuItem = NSMenuItem(
            title: "Show Language Switch HUD",
            action: #selector(toggleLanguageHUD),
            keyEquivalent: ""
        )
        showLanguageHUDMenuItem.target = self
        menu.addItem(showLanguageHUDMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // About menu item
        let aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // Quit menu item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func toggleCapsLockHUD() {
        showCapsLockHUD.toggle()
    }
    
    @objc private func toggleLanguageHUD() {
        showLanguageHUD.toggle()
    }
    
    func updateCapsLockStatus(_ isEnabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.updateIcon(capsLockEnabled: isEnabled)
            self?.capsLockMenuItem.title = isEnabled ? "Caps Lock: ON" : "Caps Lock: OFF"
        }
    }
    
    private func updateIcon(capsLockEnabled: Bool) {
        let iconName = capsLockEnabled ? "capslock.fill" : "capslock"
        let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        image?.size = NSSize(width: 18, height: 18)
        image?.isTemplate = true
        statusItem.button?.image = image
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Caps Lock & Input Language Indicator"
        alert.informativeText = "Version 1.0\n\nA menu bar app that shows HUD notifications for Caps Lock status and input language changes.\n\nYou can enable or disable individual HUD types from the menu."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
