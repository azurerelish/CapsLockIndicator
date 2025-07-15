import Cocoa
import Carbon

class CapsLockMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var lastCapsLockState: Bool = false
    private var isMonitoring = false
    private var isInitialCheck = true  // NEW: Track if this is the first check
    
    var onCapsLockChanged: ((Bool) -> Void)?
    
    init() {
        setupEventTap()
        checkInitialCapsLockState()
    }
    
    private func setupEventTap() {
        guard !isMonitoring else { return }
        
        let eventMask = (1 << CGEventType.flagsChanged.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Handle the event on main queue to avoid blocking
                DispatchQueue.main.async {
                    if let monitor = Unmanaged<CapsLockMonitor>.fromOpaque(refcon!).takeUnretainedValue() as CapsLockMonitor? {
                        monitor.handleEvent(event: event)
                    }
                }
                // Always pass the event through - CRITICAL for not blocking input
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        guard let eventTap = eventTap else {
            return
        }
        
        // Check if event tap was created successfully
        let tapEnabled = CGEvent.tapIsEnabled(tap: eventTap)
        if !tapEnabled {
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        guard let runLoopSource = runLoopSource else {
            return
        }
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        isMonitoring = true
        
        // Monitor for event tap being disabled by the system
        setupEventTapMonitoring()
    }
    
    private func setupEventTapMonitoring() {
        // Check every 5 seconds if event tap is still enabled
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkEventTapHealth()
        }
    }
    
    private func checkEventTapHealth() {
        guard let eventTap = eventTap else { return }
        
        let tapEnabled = CGEvent.tapIsEnabled(tap: eventTap)
        if !tapEnabled {
            CGEvent.tapEnable(tap: eventTap, enable: true)
            
            let stillEnabled = CGEvent.tapIsEnabled(tap: eventTap)
            if !stillEnabled {
                stop()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.setupEventTap()
                }
            }
        }
    }
    
    private func handleEvent(event: CGEvent) {
        // Keep this as lightweight as possible
        let flags = event.flags
        let capsLockPressed = flags.contains(.maskAlphaShift)
        
        if capsLockPressed != lastCapsLockState {
            lastCapsLockState = capsLockPressed
            
            // Skip initial state - don't show HUD on app startup
            if isInitialCheck {
                isInitialCheck = false
                return
            }
            
            // Call the callback asynchronously to avoid blocking
            DispatchQueue.main.async { [weak self] in
                self?.onCapsLockChanged?(capsLockPressed)
            }
        }
    }
    
    private func checkInitialCapsLockState() {
        let flags = CGEventSource.flagsState(.hidSystemState)
        let capsLockEnabled = flags.contains(.maskAlphaShift)
        lastCapsLockState = capsLockEnabled
        
        // DON'T trigger callback on initial check - just update menu bar
        DispatchQueue.main.async { [weak self] in
            // Only update menu bar, don't show HUD
            self?.onCapsLockChanged?(capsLockEnabled)
        }
        
        // After a short delay, enable normal operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isInitialCheck = false
        }
    }
    
    func stop() {
        isMonitoring = false
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
    }
    
    deinit {
        stop()
    }
}
