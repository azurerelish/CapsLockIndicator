import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menuBarController: MenuBarController!
    private var capsLockMonitor: CapsLockMonitor!
    private var inputSourceMonitor: InputSourceMonitor!
    private var hudController: HUDController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - this is critical!
        NSApp.setActivationPolicy(.accessory)
        
        // Double-check that we're not showing in dock
        if NSApp.activationPolicy() != .accessory {
            // Force it again
            NSApp.setActivationPolicy(.accessory)
        }
        
        // Initialize controllers
        setupMenuBar()
        setupMonitors()
        setupHUD()
        
        // Request accessibility permissions
        requestAccessibilityPermissions()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menuBarController = MenuBarController(statusItem: statusItem)
    }
    
    private func setupMonitors() {
        capsLockMonitor = CapsLockMonitor()
        inputSourceMonitor = InputSourceMonitor()
        
        // Set up callbacks
        capsLockMonitor.onCapsLockChanged = { [weak self] isEnabled in
            self?.menuBarController.updateCapsLockStatus(isEnabled)
            
            // Only show HUD if user has enabled it
            if self?.menuBarController.showCapsLockHUD == true {
                self?.hudController.showCapsLockStatus(isEnabled)
            }
        }
        
        inputSourceMonitor.onInputSourceChanged = { [weak self] sourceName in
            // Only show HUD if user has enabled it
            if self?.menuBarController.showLanguageHUD == true {
                self?.hudController.showInputSourceChange(sourceName)
            }
        }
    }
    
    private func setupHUD() {
        hudController = HUDController()
    }
    
    private func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            // Silently handle - user will see system prompt
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        capsLockMonitor.stop()
        inputSourceMonitor.stop()
    }
}
