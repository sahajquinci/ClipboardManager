## What's New

### Features
- **OCR Search**: Automatically extracts text from screenshots using Apple Vision framework
  - Search clipboard history by text content in images
  - Works with screenshots and any copied images
  - Uses accurate recognition level for best quality results
  
### Improvements
- **Enhanced Keyboard Navigation**: Preview popover now appears automatically when selecting long text items with arrow keys
- **Refined UX**: Consistent preview behavior across mouse and keyboard interactions
- **Stable ESC Key**: Fixed persistent issues with ESC key after system sleep/wake cycles
- **Better State Management**: Improved event monitor lifecycle and component architecture

### Bug Fixes
- Fixed selection not starting from first item
- Fixed preview blocking ESC key and global hotkey
- Fixed arrow navigation after event handling refactor
- Fixed missing AppKit import
- Fixed preview not appearing with keyboard navigation

## Technical Changes
- Integrated Apple Vision framework with VNRecognizeTextRequest
- Multi-level event monitor architecture for stable keyboard handling
- TextPreviewView component with independent ESC handling
- Automatic preview display via .onChange(of: selectedItemId)
- Enhanced clipboard item model with ocrText property

Full Changelog: https://github.com/sahajquinci/ClipboardManager/compare/v1.0.3...v1.1.0
