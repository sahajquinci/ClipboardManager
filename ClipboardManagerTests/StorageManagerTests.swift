//
//  StorageManagerTests.swift
//  ClipboardManagerTests
//
//  Created on 28 May 2026
//

import XCTest
@testable import ClipboardManager

final class StorageManagerTests: XCTestCase {
    
    var storageManager: StorageManager!
    
    override func setUp() {
        super.setUp()
        storageManager = StorageManager.shared
    }
    
    // MARK: - contentSize tests
    
    func testContentSizeForText() {
        let content = ClipboardContent.text("Hello, World!")
        let size = storageManager.contentSize(content)
        XCTAssertEqual(size, "Hello, World!".utf8.count)
    }
    
    func testContentSizeForEmptyText() {
        let content = ClipboardContent.text("")
        let size = storageManager.contentSize(content)
        XCTAssertEqual(size, 0)
    }
    
    func testContentSizeForUnicodeText() {
        let unicodeString = "こんにちは世界 🌍"
        let content = ClipboardContent.text(unicodeString)
        let size = storageManager.contentSize(content)
        XCTAssertEqual(size, unicodeString.utf8.count)
    }
    
    // MARK: - enforceStorageLimit tests
    
    func testEnforceStorageLimitDoesNothingUnderLimit() {
        let items = createTestItems(count: 5, textSize: 100)
        let totalBytes = 500
        
        let result = storageManager.enforceStorageLimit(items: items, currentTotalBytes: totalBytes)
        
        XCTAssertEqual(result.items.count, 5)
        XCTAssertEqual(result.totalBytes, totalBytes)
    }
    
    func testEnforceStorageLimitRemovesOldestItems() {
        // Create items that exceed 200MB total
        let maxBytes = storageManager.maxStorageBytes
        let itemSize = maxBytes / 3 // Each item is ~66MB
        let items = createTestItemsWithSize(count: 4, size: itemSize)
        let totalBytes = itemSize * 4 // ~266MB, over the 200MB limit
        
        let result = storageManager.enforceStorageLimit(items: items, currentTotalBytes: totalBytes)
        
        // Should have removed items from the end until under limit
        XCTAssertLessThanOrEqual(result.totalBytes, maxBytes)
        XCTAssertLessThan(result.items.count, 4)
    }
    
    func testEnforceStorageLimitPreservesNewestItems() {
        // Create items with identifiable content
        let maxBytes = storageManager.maxStorageBytes
        let bigSize = maxBytes / 2 + 1 // Just over half
        
        let item1 = ClipboardItem(content: .text(String(repeating: "A", count: bigSize)))
        let item2 = ClipboardItem(content: .text(String(repeating: "B", count: bigSize)))
        let item3 = ClipboardItem(content: .text(String(repeating: "C", count: bigSize)))
        
        let items = [item1, item2, item3] // item1 is newest (index 0)
        let totalBytes = bigSize * 3
        
        let result = storageManager.enforceStorageLimit(items: items, currentTotalBytes: totalBytes)
        
        // The oldest items (last in array) should be removed first
        XCTAssertLessThanOrEqual(result.totalBytes, maxBytes)
        // Newest item (first) should still be there
        if let firstItem = result.items.first, case .text(let text) = firstItem.content {
            XCTAssertTrue(text.hasPrefix("A"))
        } else {
            XCTFail("First item should still be the newest")
        }
    }
    
    func testEnforceStorageLimitWithEmptyList() {
        let result = storageManager.enforceStorageLimit(items: [], currentTotalBytes: 0)
        
        XCTAssertEqual(result.items.count, 0)
        XCTAssertEqual(result.totalBytes, 0)
    }
    
    func testEnforceStorageLimitExactlyAtLimit() {
        let maxBytes = storageManager.maxStorageBytes
        let items = createTestItems(count: 5, textSize: 100)
        
        let result = storageManager.enforceStorageLimit(items: items, currentTotalBytes: maxBytes)
        
        // Exactly at limit should not remove anything
        XCTAssertEqual(result.items.count, 5)
        XCTAssertEqual(result.totalBytes, maxBytes)
    }
    
    // MARK: - makeRoom tests
    
    func testMakeRoomWhenUnderLimit() {
        let items = createTestItems(count: 5, textSize: 100)
        let totalBytes = 500
        let newItemSize = 100
        
        let result = storageManager.makeRoom(for: newItemSize, items: items, currentTotalBytes: totalBytes)
        
        // Should not remove anything since 600 bytes << 200MB
        XCTAssertEqual(result.items.count, 5)
        XCTAssertEqual(result.totalBytes, totalBytes)
    }
    
    func testMakeRoomWhenOverLimit() {
        let maxBytes = storageManager.maxStorageBytes
        let itemSize = maxBytes / 2
        let items = createTestItemsWithSize(count: 2, size: itemSize)
        let totalBytes = itemSize * 2 // Exactly at limit
        let newItemSize = itemSize // Adding this would exceed
        
        let result = storageManager.makeRoom(for: newItemSize, items: items, currentTotalBytes: totalBytes)
        
        // Should have removed oldest items to make room
        XCTAssertLessThanOrEqual(result.totalBytes + newItemSize - totalBytes + result.totalBytes, maxBytes * 2)
    }
    
    func testMaxStorageBytesIs200MB() {
        XCTAssertEqual(storageManager.maxStorageBytes, 200 * 1024 * 1024)
    }
    
    // MARK: - Helpers
    
    private func createTestItems(count: Int, textSize: Int) -> [ClipboardItem] {
        return (0..<count).map { i in
            let text = String(repeating: "\(i % 10)", count: textSize)
            return ClipboardItem(content: .text(text))
        }
    }
    
    private func createTestItemsWithSize(count: Int, size: Int) -> [ClipboardItem] {
        return (0..<count).map { i in
            let text = String(repeating: "\(i % 10)", count: size)
            return ClipboardItem(content: .text(text))
        }
    }
}
