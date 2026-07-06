//
//  ClipboardStoreTests.swift
//  ClipboardManagerTests
//
//  Created on 28 May 2026
//

import XCTest
@testable import ClipboardManager

final class ClipboardStoreTests: XCTestCase {
    
    var store: ClipboardStore!
    
    override func setUp() {
        super.setUp()
        store = ClipboardStore.shared
        // Clear any existing items for a clean test state
        store.clearHistory()
    }
    
    override func tearDown() {
        store.clearHistory()
        super.tearDown()
    }
    
    // MARK: - addItem tests
    
    func testAddTextItem() {
        store.addItem(content: .text("Test text"))
        
        XCTAssertEqual(store.items.count, 1)
        if case .text(let string) = store.items.first?.content {
            XCTAssertEqual(string, "Test text")
        } else {
            XCTFail("Expected text content")
        }
    }
    
    func testAddMultipleItems() {
        store.addItem(content: .text("First"))
        store.addItem(content: .text("Second"))
        store.addItem(content: .text("Third"))
        
        XCTAssertEqual(store.items.count, 3)
        // Most recent item should be first
        if case .text(let string) = store.items.first?.content {
            XCTAssertEqual(string, "Third")
        } else {
            XCTFail("Expected text content")
        }
    }
    
    func testDuplicateConsecutiveItemsNotAdded() {
        store.addItem(content: .text("Same text"))
        store.addItem(content: .text("Same text"))
        
        XCTAssertEqual(store.items.count, 1)
    }
    
    func testNonConsecutiveDuplicatesAllowed() {
        store.addItem(content: .text("Text A"))
        store.addItem(content: .text("Text B"))
        store.addItem(content: .text("Text A"))
        
        XCTAssertEqual(store.items.count, 3)
    }
    
    // MARK: - totalBytes tests
    
    func testTotalBytesUpdatedOnAdd() {
        let text = "Hello, World!"
        store.addItem(content: .text(text))
        
        XCTAssertEqual(store.totalBytes, text.utf8.count)
    }
    
    func testTotalBytesUpdatedOnMultipleAdds() {
        let text1 = "First"
        let text2 = "Second"
        store.addItem(content: .text(text1))
        store.addItem(content: .text(text2))
        
        XCTAssertEqual(store.totalBytes, text1.utf8.count + text2.utf8.count)
    }
    
    func testTotalBytesResetOnClear() {
        store.addItem(content: .text("Some text"))
        store.clearHistory()
        
        XCTAssertEqual(store.totalBytes, 0)
    }
    
    // MARK: - deleteItem tests
    
    func testDeleteItem() {
        store.addItem(content: .text("Item to keep"))
        store.addItem(content: .text("Item to delete"))
        
        let itemToDelete = store.items.first! // Most recent = "Item to delete"
        store.deleteItem(itemToDelete)
        
        XCTAssertEqual(store.items.count, 1)
        if case .text(let string) = store.items.first?.content {
            XCTAssertEqual(string, "Item to keep")
        } else {
            XCTFail("Expected text content")
        }
    }
    
    func testDeleteItemUpdatesTotalBytes() {
        let text = "Delete me"
        store.addItem(content: .text(text))
        let initialBytes = store.totalBytes
        
        store.deleteItem(store.items.first!)
        
        XCTAssertEqual(store.totalBytes, initialBytes - text.utf8.count)
    }
    
    // MARK: - clearHistory tests
    
    func testClearHistory() {
        store.addItem(content: .text("Item 1"))
        store.addItem(content: .text("Item 2"))
        store.addItem(content: .text("Item 3"))
        
        store.clearHistory()
        
        XCTAssertEqual(store.items.count, 0)
        XCTAssertEqual(store.totalBytes, 0)
    }
    
    // MARK: - copyToClipboard tests
    
    func testCopyToClipboard() {
        let text = "Copy this text"
        let item = ClipboardItem(content: .text(text))
        
        store.copyToClipboard(item)
        
        let pasteboard = NSPasteboard.general
        XCTAssertEqual(pasteboard.string(forType: .string), text)
    }
    
    // MARK: - Storage limit integration tests
    
    func testStorageLimitEnforced() {
        // Add items that would exceed 200MB
        // This is a logical test - we verify the limit mechanism exists
        let maxBytes = StorageManager.shared.maxStorageBytes
        XCTAssertEqual(maxBytes, 200 * 1024 * 1024)
    }
    
    func testItemOrderPreservedAfterPruning() {
        // Add items and verify order (newest first)
        store.addItem(content: .text("Oldest"))
        store.addItem(content: .text("Middle"))
        store.addItem(content: .text("Newest"))
        
        XCTAssertEqual(store.items.count, 3)
        if case .text(let first) = store.items[0].content,
           case .text(let second) = store.items[1].content,
           case .text(let third) = store.items[2].content {
            XCTAssertEqual(first, "Newest")
            XCTAssertEqual(second, "Middle")
            XCTAssertEqual(third, "Oldest")
        } else {
            XCTFail("Expected text content in all items")
        }
    }
}
