# CapsLockIndicator

CapsLockIndicator is a macOS menu bar application that displays HUD notifications whenever the Caps Lock key is toggled or the keyboard input source is changed. Inspired by Apple's typical HUD design, the app provides visual feedback for these events.

## Features

- **Caps Lock Status Monitoring:** Instant HUD notification when Caps Lock is turned on or off.
- **Input Source Change Detection:** Detect and notify when the keyboard input language is switched.
- **Menu Bar Integration:** Seamlessly integrates into the macOS menu bar with customizable preferences.
- **Customizable HUDs:** Options to enable or disable individual HUDs for Caps Lock and input source changes.
- **Accessibility:** Built-in checks and requests for accessibility permissions to ensure functionality.

## Installation
### Download from Releases
Simply download the compiled app and save it in your Application folder

### Build from Source
1. Clone this repository
2. Create a new macOS app project in Xcode
3. Add the Swift files from the `Sources/` directory
4. Copy the Info.plist settings to your project
5. Build and run!

## Usage

- **Running the App:**
  - The app runs in the background as a menu bar item. It’s not shown in the Dock.
- **Accessing Preferences:**
  - Click on the menu bar icon to access preferences.
  - Toggle the visibility of Caps Lock and input source HUDs.

## Technical Details

- **Languages & Technologies:**
  - Developed using Swift, leveraging Cocoa framework.
  - Uses Carbon API for keyboard events.

- **Architecture:**
  - `AppDelegate` handles app lifecycle and initialization of controllers.
  - `CapsLockMonitor` and `InputSourceMonitor` manage event listening.
  - `HUDController` creates visual HUD notifications.
  - `MenuBarController` manages the menu bar icon and preferences.

## Permissions

To function correctly, CapsLockIndicator requires the following:
- Accessibility permissions for capturing key events and input source changes.

Check that the app has accessibility permissions in `System Preferences > Security & Privacy > Privacy > Accessibility`.

## Troubleshooting

- If the HUD does not appear:
  - Confirm accessibility permissions are granted.
  - Check logs for any error messages during initialization.

## Contributing

Feel free to fork the repository and submit pull requests. Please ensure code quality and follow existing coding styles.



<img width="1566" height="1610" alt="CleanShot 2025-07-14 at 22 05 46@2x" src="https://github.com/user-attachments/assets/ed79dd7f-6243-46ad-8e6c-b9c4f7161587" />

