//
//  ClipboardManagerApp.swift
//  ClipboardManager
//
//  Created on 9 January 2026
//

import SwiftUI

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
