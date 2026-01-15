//
//  ClipboardMonitor.swift
//  ClipboardManager
//
//  Created on 9 January 2026
//

import Cocoa
import SwiftUI
import Vision

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
                // Perform OCR on the image asynchronously
                performOCR(on: nsImage) { ocrText in
                    ClipboardStore.shared.addItem(content: .image(nsImage), ocrText: ocrText)
                }
            }
        }
    }
    
    private func performOCR(on image: NSImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            completion(recognizedText.isEmpty ? nil : recognizedText)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("OCR error: \(error)")
                completion(nil)
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
