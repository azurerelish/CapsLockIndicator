import Cocoa
import Carbon

class InputSourceMonitor {
    private var lastInputSource: String = ""
    private var observer: Any?
    
    var onInputSourceChanged: ((String) -> Void)?
    
    init() {
        setupInputSourceMonitoring()
        checkInitialInputSource()
    }
    
    private func setupInputSourceMonitoring() {
        observer = DistributedNotificationCenter.default.addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleInputSourceChange()
        }
    }
    
    private func handleInputSourceChange() {
        let currentInputSource = getCurrentInputSourceName()
        
        if currentInputSource != lastInputSource && !currentInputSource.isEmpty {
            lastInputSource = currentInputSource
            onInputSourceChanged?(currentInputSource)
        }
    }
    
    private func checkInitialInputSource() {
        lastInputSource = getCurrentInputSourceName()
    }
    
    private func getCurrentInputSourceName() -> String {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return ""
        }
        
        // Try to get localized name first
        if let localizedName = TISGetInputSourceProperty(inputSource, kTISPropertyLocalizedName) {
            let name = Unmanaged<CFString>.fromOpaque(localizedName).takeUnretainedValue() as String
            return name
        }
        
        // Fall back to input source ID
        if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            let id = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
            return formatInputSourceID(id)
        }
        
        return "Unknown"
    }
    
    private func formatInputSourceID(_ id: String) -> String {
        // Convert common input source IDs to readable names
        let commonMappings = [
            "com.apple.keylayout.US": "English (US)",
            "com.apple.keylayout.ABC": "ABC",
            "com.apple.keylayout.British": "English (UK)",
            "com.apple.keylayout.Canadian": "English (Canada)",
            "com.apple.keylayout.Spanish": "Spanish",
            "com.apple.keylayout.French": "French",
            "com.apple.keylayout.German": "German",
            "com.apple.keylayout.Italian": "Italian",
            "com.apple.keylayout.Japanese": "Japanese",
            "com.apple.keylayout.Korean": "Korean",
            "com.apple.keylayout.ChineseSimplified": "Chinese (Simplified)",
            "com.apple.keylayout.ChineseTraditional": "Chinese (Traditional)"
        ]
        
        if let mappedName = commonMappings[id] {
            return mappedName
        }
        
        // Extract readable name from ID
        if let lastComponent = id.components(separatedBy: ".").last {
            return lastComponent.replacingOccurrences(of: "_", with: " ")
        }
        
        return id
    }
    
    func stop() {
        if let observer = observer {
            DistributedNotificationCenter.default.removeObserver(observer)
        }
    }
    
    deinit {
        stop()
    }
}
