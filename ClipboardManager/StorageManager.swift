//
//  StorageManager.swift
//  ClipboardManager
//
//  Created on 28 May 2026
//

import Foundation

/// Service responsible for enforcing storage limits on clipboard history.
/// Removes oldest items when the total storage exceeds the configured maximum.
class StorageManager {
    static let shared = StorageManager()
    
    /// Maximum storage size in bytes (200 MB)
    let maxStorageBytes: Int = 200 * 1024 * 1024
    
    private init() {}
    
    /// Calculates the size in bytes of a ClipboardContent item.
    func contentSize(_ content: ClipboardContent) -> Int {
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
    
    /// Enforces the storage limit by removing oldest items until total size is within bounds.
    /// Returns the pruned array and the new total size.
    func enforceStorageLimit(items: [ClipboardItem], currentTotalBytes: Int) -> (items: [ClipboardItem], totalBytes: Int) {
        var prunedItems = items
        var totalBytes = currentTotalBytes
        
        while totalBytes > maxStorageBytes && !prunedItems.isEmpty {
            let removedItem = prunedItems.removeLast()
            totalBytes -= contentSize(removedItem.content)
        }
        
        // Ensure totalBytes doesn't go negative due to any rounding
        if totalBytes < 0 {
            totalBytes = 0
        }
        
        return (prunedItems, totalBytes)
    }
    
    /// Checks if adding a new item would exceed the storage limit, and if so,
    /// removes oldest items to make room.
    func makeRoom(for newContentSize: Int, items: [ClipboardItem], currentTotalBytes: Int) -> (items: [ClipboardItem], totalBytes: Int) {
        let projectedTotal = currentTotalBytes + newContentSize
        if projectedTotal <= maxStorageBytes {
            return (items, currentTotalBytes)
        }
        return enforceStorageLimit(items: items, currentTotalBytes: projectedTotal)
    }
}
