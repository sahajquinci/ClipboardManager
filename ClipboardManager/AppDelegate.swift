//
//  AppDelegate.swift
//  ClipboardManager
//
//  Created on 9 January 2026
//

import Cocoa
import SwiftUI
import Carbon
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var clipboardMonitor: ClipboardMonitor!
    var hotKeyRef: EventHotKeyRef?
    var keyboardEventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Manager")
            button.action = #selector(togglePopover)
        }
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 450, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView().environmentObject(self))
        
        // Start clipboard monitoring
        clipboardMonitor = ClipboardMonitor()
        clipboardMonitor.startMonitoring()
        
        // Register global hotkey (Command+Shift+V)
        registerHotkey()
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                // Clean up keyboard monitor when closing
                if let monitor = keyboardEventMonitor {
                    NSEvent.removeMonitor(monitor)
                    keyboardEventMonitor = nil
                }
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
                
                // Set up keyboard monitor when opening - delayed to ensure view is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // Remove any existing monitor first
                    if let monitor = self.keyboardEventMonitor {
                        NSEvent.removeMonitor(monitor)
                    }
                    
                    // Add fresh keyboard event monitor
                    self.keyboardEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                        let keyCode = Int(event.keyCode)
                        
                        // Handle ESC key to close popover
                        if keyCode == 53 { // ESC
                            self.closePopover()
                            return nil
                        }
                        
                        return event
                    }
                }
            }
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
        // Deactivate the app to return focus to the previous application
        NSApp.hide(nil)
    }
    
    func registerHotkey() {
        // Register Command+Shift+V using Carbon Event Manager
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D435143), id: 1) // 'MCLC' signature
        
        var eventHandler: EventHandlerRef?
        let eventSpec = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        ]
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            // Get the AppDelegate instance
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            
            // Toggle the popover
            DispatchQueue.main.async {
                appDelegate.togglePopover()
            }
            
            return noErr
        }, 1, eventSpec, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        
        // Register the hotkey: Command+Shift+V (keyCode 9 for V)
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        RegisterEventHotKey(9, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        // Also keep the local monitor as a fallback for when the app is focused
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 9 {
                self.togglePopover()
                return nil
            }
            return event
        }
    }
}
