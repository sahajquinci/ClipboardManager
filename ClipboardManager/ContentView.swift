//
//  ContentView.swift
//  ClipboardManager
//
//  Created on 9 January 2026
//

import SwiftUI
import ServiceManagement

struct ContentView: View {
    @ObservedObject var store = ClipboardStore.shared
    @State private var searchText = ""
    @State private var showingClearAlert = false
    @State private var selectedItemId: UUID?
    @State private var launchAtLogin: Bool = UserDefaults.standard.bool(forKey: "launchAtLogin")
    @State private var filterText = true
    @State private var filterLinks = true
    @State private var filterImages = true
    @FocusState private var searchFieldFocused: Bool
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var eventMonitor: Any?
    
    var filteredItems: [ClipboardItem] {
        return store.items.filter { item in
            // Apply content type filters
            let matchesContentFilter: Bool
            switch item.content {
            case .text(let string):
                let isLink = isURL(string)
                if isLink {
                    matchesContentFilter = filterLinks
                } else {
                    matchesContentFilter = filterText
                }
            case .image:
                matchesContentFilter = filterImages
            }
            
            if !matchesContentFilter {
                return false
            }
            
            // Apply search filter
            if searchText.isEmpty {
                return true
            } else {
                switch item.content {
                case .text(let string):
                    return string.localizedCaseInsensitiveContains(searchText)
                case .image:
                    // Search in OCR text if available
                    if let ocrText = item.ocrText {
                        return ocrText.localizedCaseInsensitiveContains(searchText)
                    }
                    return false
                }
            }
        }
    }
    
    var totalSize: String {
        let totalBytes = store.totalBytes
        
        if totalBytes < 1024 {
            return "\(totalBytes) B"
        } else if totalBytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(totalBytes) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(totalBytes) / (1024.0 * 1024.0))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clipboard History")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Image(systemName: "internaldrive")
                            .font(.caption2)
                        Text(totalSize)
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
                Spacer()
                
                Toggle(isOn: $launchAtLogin) {
                    Text("Launch at Login")
                        .font(.caption)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
                .onChange(of: launchAtLogin) { newValue in
                    setLaunchAtLogin(enabled: newValue)
                }
                
                Button(action: {
                    showingClearAlert = true
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .help("Clear History")
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.plain)
                .help("Quit")
            }
            .padding()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search clipboard...", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($searchFieldFocused)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Content type filters
            HStack(spacing: 12) {
                FilterButton(icon: "doc.text", label: "Text", isActive: $filterText)
                FilterButton(icon: "link", label: "Links", isActive: $filterLinks)
                FilterButton(icon: "photo", label: "Images", isActive: $filterImages)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Clipboard items list
            if filteredItems.isEmpty {
                VStack {
                    Spacer()
                    Text(searchText.isEmpty ? "No clipboard history" : "No results")
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredItems) { item in
                                ClipboardItemRow(
                                    item: item,
                                    isSelected: selectedItemId == item.id,
                                    showPreviewForSelected: selectedItemId == item.id,
                                    onCopy: {
                                        copyItem(item)
                                        appDelegate.closePopover()
                                    }
                                )
                                .id(item.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedItemId = item.id
                                }
                            }
                        }
                    }
                    .onChange(of: selectedItemId) { newValue in
                        if let id = newValue {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("↑↓ Navigate • ⏎ Select • ⌘⇧V Toggle")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(filteredItems.count) items")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 450, height: 500)
        .alert("Clear History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                store.clearHistory()
                selectedItemId = nil
            }
        } message: {
            Text("Are you sure you want to clear all clipboard history?")
        }
        .onAppear {
            // Select first item by default when popover opens
            if !filteredItems.isEmpty {
                selectedItemId = filteredItems.first?.id
            }
            // Focus search field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                searchFieldFocused = true
            }
            
            // Add keyboard event monitor when popover appears
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                return self.handleKeyEvent(event)
            }
        }
        .onDisappear {
            // Clean up event monitor when popover disappears
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
    
    private func copyItem(_ item: ClipboardItem) {
        // Pause monitoring to avoid re-adding the same item
        if let monitor = (NSApp.delegate as? AppDelegate)?.clipboardMonitor {
            monitor.pauseMonitoring()
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.content {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let image):
            pasteboard.writeObjects([image])
        }
    }
    
    private func selectAndCopyItem(_ item: ClipboardItem) {
        copyItem(item)
        appDelegate.closePopover()
    }
    
    private func setLaunchAtLogin(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            }
        }
    }    
    private func isURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        let matches = detector.matches(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed))
        return !matches.isEmpty && matches.first?.range.length == trimmed.count
    }
    
    private func itemSize(_ item: ClipboardItem) -> String {
        let bytes: Int
        switch item.content {
        case .text(let string):
            bytes = string.utf8.count
        case .image(let nsImage):
            if let tiffData = nsImage.tiffRepresentation {
                bytes = tiffData.count
            } else {
                bytes = 0
            }
        }
        
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let keyCode = Int(event.keyCode)
        
        // Handle ESC key to close popover
        if keyCode == 53 { // ESC
            appDelegate.closePopover()
            return nil
        }
        
        // Handle arrow keys for navigation
        if keyCode == 125 { // Down arrow
            searchFieldFocused = false
            moveSelection(up: false)
            return nil
        } else if keyCode == 126 { // Up arrow
            searchFieldFocused = false
            moveSelection(up: true)
            return nil
        } else if keyCode == 36 { // Return/Enter
            if let selectedId = selectedItemId,
               let item = filteredItems.first(where: { $0.id == selectedId }) {
                selectAndCopyItem(item)
                return nil
            }
        } else if !event.modifierFlags.contains(.command) {
            // For regular typing, focus search field
            if !searchFieldFocused {
                searchFieldFocused = true
            }
        }
        
        return event
    }
    
    private func moveSelection(up: Bool) {
        guard !filteredItems.isEmpty else { return }
        
        // If no selection or selection not in filtered items, start from first item
        guard let currentId = selectedItemId,
              let currentIndex = filteredItems.firstIndex(where: { $0.id == currentId }) else {
            selectedItemId = filteredItems.first?.id
            return
        }
        
        let newIndex: Int
        if up {
            newIndex = currentIndex > 0 ? currentIndex - 1 : filteredItems.count - 1
        } else {
            newIndex = currentIndex < filteredItems.count - 1 ? currentIndex + 1 : 0
        }
        selectedItemId = filteredItems[newIndex].id
    }
}

// Filter button component
struct FilterButton: View {
    let icon: String
    let label: String
    @Binding var isActive: Bool
    
    var body: some View {
        Button(action: {
            isActive.toggle()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isActive ? .blue : .gray)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let showPreviewForSelected: Bool
    let onCopy: () -> Void
    
    @State private var isHovering = false
    @State private var showPreview = false
    
    var itemSize: String {
        let bytes: Int
        switch item.content {
        case .text(let string):
            bytes = string.utf8.count
        case .image(let nsImage):
            if let tiffData = nsImage.tiffRepresentation {
                bytes = tiffData.count
            } else {
                bytes = 0
            }
        }
        
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Content
            Group {
                switch item.content {
                case .text(let string):
                    Text(string)
                        .lineLimit(3)
                        .font(.system(.body, design: .default))
                        .onHover { hovering in
                            isHovering = hovering
                            if hovering && string.count > 100 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    if isHovering {
                                        showPreview = true
                                    }
                                }
                            } else {
                                showPreview = false
                            }
                        }
                        .popover(isPresented: Binding(
                            get: { showPreview || (showPreviewForSelected && string.count > 100) },
                            set: { showPreview = $0 }
                        ), arrowEdge: .trailing) {
                            ScrollView {
                                Text(string)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding()
                                    .frame(maxWidth: 500)
                            }
                            .frame(width: 500, height: 400)
                            .onAppear {
                                // Add local key monitor for ESC key to close preview
                                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                                    if event.keyCode == 53 { // ESC key
                                        showPreview = false
                                        return nil
                                    }
                                    return event
                                }
                            }
                        }
                case .image(let nsImage):
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 80)
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Size indicator
                HStack(spacing: 3) {
                    Image(systemName: "doc.text")
                        .font(.caption2)
                    Text(itemSize)
                        .font(.caption2)
                }
                .foregroundColor(.gray)
                
                // Copy button
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Copy")
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
    }
}
