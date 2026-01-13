# ClipboardManager

A free, unlimited clipboard history manager for macOS. Built with Swift and SwiftUI.

## Features

- ✅ **Unlimited History** - No restrictions on how many items you can save
- 🔍 **Search** - Quickly find any clipboard item
- 🖼️ **Images & Text** - Support for both text and image clipboard content
- 🗑️ **Clear History** - One-click to clear all history
- ⌨️ **Keyboard Shortcut** - Press `⌘⇧V` to show/hide the clipboard manager
- 📍 **Menu Bar** - Quick access from the menu bar
- 💾 **Persistent Storage** - History saved between app launches
- 🚀 **Native & Fast** - Built with SwiftUI for Apple Silicon

## Requirements

- macOS 13.0 or later
- Apple Silicon (M1/M2/M3) or Intel Mac

## Installation

### From DMG (Recommended)

1. Download `ClipboardManager.dmg`
2. Open the DMG file
3. Drag `ClipboardManager` to your Applications folder
4. Launch from Applications
5. The app will appear in your menu bar

### Build from Source

```bash
# Clone the repository
git clone <your-repo-url>
cd CopyQ

# Make build script executable
chmod +x build.sh

# Build and create DMG
./build.sh
```

## Usage

1. **Launch the App** - The clipboard icon appears in your menu bar
2. **Copy Anything** - Copy text or images as usual
3. **Access History** - Click the menu bar icon or press `⌘⇧V`
4. **Select Item** - Click any item to copy it back to clipboard
5. **Search** - Type in the search box to filter items
6. **Clear History** - Click the trash icon to clear all history

## Keyboard Shortcuts

- `⌘⇧V` - Show/hide clipboard history window

## Privacy

All clipboard data is stored locally on your Mac in UserDefaults. No data is ever sent to external servers.

## Building

### Prerequisites

- Xcode 15.0 or later
- macOS 13.0 SDK or later

### Build Commands

```bash
# Build app
xcodebuild -project ClipboardManager.xcodeproj \
    -scheme ClipboardManager \
    -configuration Release \
    -arch arm64 \
    clean build

# Or use the build script
./build.sh
```

## Donation

If this app saves you time feel free to show your appreciation using the
following button :D

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate?hosted_button_id=W8J2B4E92NEQ2)

## License

Free to use and modify for personal use.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.
