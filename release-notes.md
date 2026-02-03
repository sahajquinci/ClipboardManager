## v1.1.1 - Bug Fixes

### Bug Fixes
- **Fixed Selection Reset**: Selection now properly resets to first item when opening the popover
- **Fixed Keyboard Input**: Typing after arrow navigation now works without beep or missing first letter
- **Simplified Event Handling**: Keyboard event handler now only consumes arrow/enter keys, letting all other input pass through naturally

### Known Issues
- Performance may degrade with very large clipboard history (many items)

Full Changelog: https://github.com/sahajquinci/ClipboardManager/compare/v1.1.0...v1.1.1
