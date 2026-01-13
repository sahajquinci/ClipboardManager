//
//  ClipboardMonitor.swift
//  ClipboardManager
//
//  Created on 9 January 2026
//

import Cocoa
import SwiftUI

class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var shouldIgnoreNextChange = false
    
    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func pauseMonitoring() {
        shouldIgnoreNextChange = true
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            // Skip this change if we're ignoring it
            if shouldIgnoreNextChange {
                shouldIgnoreNextChange = false
                return
            }
            
            if let string = pasteboard.string(forType: .string) {
                ClipboardStore.shared.addItem(content: .text(string))
            } else if let image = pasteboard.data(forType: .tiff),
                      let nsImage = NSImage(data: image) {
                ClipboardStore.shared.addItem(content: .image(nsImage))
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
