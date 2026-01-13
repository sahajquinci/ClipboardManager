//
//  ClipboardStore.swift
//  ClipboardManager
//
//  Created on 9 January 2026
//

import Cocoa
import SwiftUI

enum ClipboardContent: Identifiable, Codable {
    case text(String)
    case image(NSImage)
    
    var id: UUID {
        return UUID()
    }
    
    enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    enum ContentType: String, Codable {
        case text, image
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let string):
            try container.encode(ContentType.text, forKey: .type)
            try container.encode(string, forKey: .data)
        case .image(let image):
            try container.encode(ContentType.image, forKey: .type)
            if let tiffData = image.tiffRepresentation {
                try container.encode(tiffData, forKey: .data)
            }
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        
        switch type {
        case .text:
            let string = try container.decode(String.self, forKey: .data)
            self = .text(string)
        case .image:
            let data = try container.decode(Data.self, forKey: .data)
            if let image = NSImage(data: data) {
                self = .image(image)
            } else {
                throw DecodingError.dataCorruptedError(forKey: .data, in: container, debugDescription: "Invalid image data")
            }
        }
    }
}

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date
    
    init(content: ClipboardContent) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
    }
}

class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()
    
    @Published var items: [ClipboardItem] = []
    @Published var totalBytes: Int = 0
    
    private let saveKey = "ClipboardHistory"
    private let maxItems = 1000 // Reasonable limit to prevent excessive memory usage
    
    private init() {
        loadItems()
        recalculateTotalSize()
    }
    
    private func itemSize(_ content: ClipboardContent) -> Int {
        switch content {
        case .text(let string):
            return string.utf8.count
        case .image(let nsImage):
            if let tiffData = nsImage.tiffRepresentation {
                return tiffData.count
            }
            return 0
        }
    }
    
    private func recalculateTotalSize() {
        totalBytes = items.reduce(0) { total, item in
            total + itemSize(item.content)
        }
    }
    
    func addItem(content: ClipboardContent) {
        // Don't add duplicate consecutive items
        if let lastItem = items.first {
            switch (lastItem.content, content) {
            case (.text(let last), .text(let new)) where last == new:
                return
            default:
                break
            }
        }
        
        let item = ClipboardItem(content: content)
        let newItemSize = itemSize(content)
        items.insert(item, at: 0)
        totalBytes += newItemSize
        
        // Keep only the most recent items
        if items.count > maxItems {
            let removedItem = items[maxItems]
            totalBytes -= itemSize(removedItem.content)
            items = Array(items.prefix(maxItems))
        }
        
        saveItems()
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.content {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let image):
            if let tiffData = image.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
            }
        }
    }
    
    func clearHistory() {
        items.removeAll()
        totalBytes = 0
        saveItems()
    }
    
    func deleteItem(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let removedItem = items[index]
            totalBytes -= itemSize(removedItem.content)
            items.remove(at: index)
            saveItems()
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
            recalculateTotalSize()
        }
    }
}
