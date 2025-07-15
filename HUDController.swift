import Cocoa

class HUDController {
    private var hudWindow: NSWindow?
    private var hideWorkItem: DispatchWorkItem?
    private var hudWindowId: Int = 0  // NEW: Track window IDs
    private var emergencyCleanupTimer: Timer?  // NEW: Failsafe timer
    
    func showCapsLockStatus(_ isEnabled: Bool) {
        let iconName = isEnabled ? "capslock.fill" : "capslock"
        let text = isEnabled ? "Caps Lock ON" : "Caps Lock OFF"
        let color = isEnabled ? NSColor.systemBlue : NSColor.secondaryLabelColor
        showHUD(iconName: iconName, text: text, iconColor: color)
    }
    
    func showInputSourceChange(_ sourceName: String) {
        showHUD(iconName: "globe", text: sourceName, iconColor: NSColor.secondaryLabelColor)
    }
    
    private func showHUD(iconName: String, text: String, iconColor: NSColor) {
        // CRITICAL: Always run on main thread and ensure cleanup happens first
        DispatchQueue.main.async { [weak self] in
            // Force cleanup any existing HUD immediately
            self?.emergencyCleanup()
            
            // Create new HUD with unique ID
            self?.hudWindowId += 1
            let currentId = self?.hudWindowId ?? 0
            
            // Small delay to ensure cleanup completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                // Only proceed if we're still the latest request
                guard self?.hudWindowId == currentId else { return }
                
                self?.createAndShowWindow(iconName: iconName, text: text, iconColor: iconColor)
                self?.scheduleHide(for: currentId)
                self?.scheduleEmergencyCleanup()
            }
        }
    }
    
    private func emergencyCleanup() {
        // Cancel ALL operations
        hideWorkItem?.cancel()
        hideWorkItem = nil
        emergencyCleanupTimer?.invalidate()
        emergencyCleanupTimer = nil
        
        // Force hide any window immediately
        if let window = hudWindow {
            window.alphaValue = 0
            window.orderOut(nil)
            hudWindow = nil
        }
        
        // Clear any animations
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0
        })
    }
    
    private func scheduleEmergencyCleanup() {
        // NEW: Failsafe - force cleanup after 3 seconds no matter what
        emergencyCleanupTimer?.invalidate()
        emergencyCleanupTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.emergencyCleanup()
        }
    }
    
    private func cleanupHUD() {
        // Cancel any pending hide operation
        hideWorkItem?.cancel()
        hideWorkItem = nil
        
        // Clean up existing window
        if let window = hudWindow {
            window.orderOut(nil)
            hudWindow = nil
        }
    }
    
    private func forceCleanupHUD() {
        // ENHANCED: Force cleanup with additional safety
        hideWorkItem?.cancel()
        hideWorkItem = nil
        
        if let window = hudWindow {
            // Force immediate cleanup
            window.alphaValue = 0
            window.orderOut(nil)
            hudWindow = nil
        }
        
        // Clear any lingering animations
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0
        })
    }
    
    private func createAndShowWindow(iconName: String, text: String, iconColor: NSColor) {
        // Get screen where the mouse cursor is currently located
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main
        
        guard let screen = targetScreen else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = NSSize(width: 200, height: 200)
        
        // Position window
        let windowOrigin = NSPoint(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.minY + 140 // 150 pixels from bottom
        )
        
        let windowFrame = NSRect(origin: windowOrigin, size: windowSize)
        
        // Create window with no style mask for borderless appearance
        let window = NSWindow(
            contentRect: windowFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties - NO SHADOW to prevent lines
        window.level = .floating
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false  // ← CHANGED: No shadow to prevent border lines
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Create the HUD content view
        let contentView = createHUDContentView(iconName: iconName, text: text, iconColor: iconColor, size: windowSize)
        window.contentView = contentView
        
        // Store reference and show
        self.hudWindow = window
        window.orderFront(nil)
    }
    
    private func createHUDContentView(iconName: String, text: String, iconColor: NSColor, size: NSSize) -> NSView {
        let containerView = NSView(frame: NSRect(origin: .zero, size: size))
        
        // Create visual effect view for the blurred background - COMPLETELY BORDERLESS
        let effectView = NSVisualEffectView(frame: containerView.bounds)
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 12
        effectView.layer?.masksToBounds = true
        
        // ENHANCED: Completely remove any potential borders
        effectView.layer?.borderWidth = 0
        effectView.layer?.borderColor = nil
        effectView.layer?.shouldRasterize = false
        effectView.layer?.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        containerView.addSubview(effectView)
        
        // Create icon image view
        let iconView = NSImageView()
        if let iconImage = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            // Configure the icon - make it larger for the bigger square
            let config = NSImage.SymbolConfiguration(pointSize: 48, weight: .medium)
            let configuredImage = iconImage.withSymbolConfiguration(config)
            iconView.image = configuredImage
            iconView.contentTintColor = iconColor
        }
        
        // Position icon in the center of the square
        let iconSize = NSSize(width: 60, height: 60)
        iconView.frame = NSRect(
            x: (size.width - iconSize.width) / 2,
            y: (size.height - iconSize.height) / 2 + 10, // Slightly above center to account for text
            width: iconSize.width,
            height: iconSize.height
        )
        containerView.addSubview(iconView)
        
        // Create text label
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = NSColor.labelColor
        label.alignment = .center
        label.backgroundColor = NSColor.clear
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        label.maximumNumberOfLines = 1
        
        // Size and position label below the centered icon
        label.sizeToFit()
        let labelSize = label.fittingSize
        label.frame = NSRect(
            x: (size.width - labelSize.width) / 2,
            y: (size.height / 2) - 40, // Below the icon
            width: min(labelSize.width, size.width - 20),
            height: labelSize.height
        )
        containerView.addSubview(label)
        
        return containerView
    }
    
    private func scheduleHide(for windowId: Int) {
        // ENHANCED: Ensure no overlapping timers
        hideWorkItem?.cancel()  // Cancel any existing timer first
        
        let workItem = DispatchWorkItem { [weak self] in
            // Only proceed if this is still the current window
            guard let strongSelf = self,
                  strongSelf.hudWindowId == windowId,
                  strongSelf.hideWorkItem != nil else { return }
            strongSelf.hideHUD()
        }
        
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }
    
    private func hideHUD() {
        guard let window = hudWindow else { return }
        
        // Clear the work item reference immediately
        hideWorkItem = nil
        emergencyCleanupTimer?.invalidate()
        emergencyCleanupTimer = nil
        
        // Smooth fade out animation like native macOS HUDs
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0.0
        }) { [weak self] in
            // After animation completes, remove the window
            DispatchQueue.main.async { [weak self] in
                // Only cleanup if this is still our window
                if self?.hudWindow === window {
                    window.orderOut(nil)
                    self?.hudWindow = nil
                }
            }
        }
    }
}
