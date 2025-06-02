# EZVIZ Flutter Native SDK Demo App

A comprehensive example application showcasing the native EZVIZ SDK integration for Flutter, featuring device management, live streaming, PTZ control, audio/intercom capabilities, and recording functions.

## Features Demonstrated

### 🚀 **Native SDK Integration**
- Full native Android/iOS SDK initialization
- Proper SDK lifecycle management
- Error handling and status monitoring

### 📱 **Device Management** 
- Device discovery and listing
- Real-time device status monitoring
- Device selection and verification code support
- Encrypted device handling

### 📺 **Live Video Streaming**
- Hardware-accelerated native video player
- High-performance real-time streaming
- Multiple video quality support
- Seamless player initialization

### 🎮 **PTZ (Pan-Tilt-Zoom) Controls**
- Intuitive directional controls (Up, Down, Left, Right)
- Zoom In/Out functionality
- Preset positioning
- Touch-based control interface
- Real-time PTZ command execution

### 🎤 **Audio & Intercom Features**
- Two-way audio communication
- Voice talk (intercom) functionality
- Audio enable/disable controls
- Real-time audio streaming

### 📹 **Recording & Screenshots**
- Start/stop video recording during live streaming
- Capture screenshots
- Recording status monitoring
- File management integration

### 📶 **WiFi Configuration** (Coming Soon)
- Device network setup
- AP mode configuration
- Sound wave configuration

## Prerequisites

### EZVIZ Developer Account
1. Register at [EZVIZ Open Platform](https://open.ezviz.com/)
2. Create an application to get:
   - **App Key** (Required)
   - **App Secret** (Required)  
   - **Access Token** (Optional, can be generated via App Key/Secret)

### Platform Requirements

#### Android
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Permissions**: Camera, Microphone, Storage

#### iOS  
- **Min Version**: 12.0
- **Permissions**: Camera, Microphone, Photo Library

## Installation & Setup

### 1. Clone and Setup
```bash
git clone <repository-url>
cd ezviz_example_app
flutter pub get
```

### 2. Platform Configuration

#### Android Setup
Add the following permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
```

#### iOS Setup
Add the following to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for video streaming</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for audio communication</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save screenshots</string>
```

### 3. Run the App
```bash
flutter run
```

## Using the Demo App

### Tab 1: SDK Initialization
1. **Enter Credentials**: Input your EZVIZ App Key and App Secret
2. **Optional**: Add Access Token if available
3. **Initialize**: Tap "Initialize SDK" to connect to EZVIZ services
4. **Status**: Monitor initialization status and error messages

### Tab 2: Device Management
1. **Load Devices**: Tap "Load Devices" after SDK initialization
2. **Select Device**: Tap on any device from the list to select it
3. **Verify Code**: Enter the device verification code if the device is encrypted
   - Usually found on device sticker or in device settings
   - Required for password-protected cameras

### Tab 3: Live Streaming
1. **Initialize Player**: Create native video player for selected device
2. **Start Live Stream**: Begin real-time video streaming
3. **Video Display**: View live feed in hardware-accelerated player
4. **Stop Stream**: End streaming and release resources

### Tab 4: PTZ Control
1. **Directional Controls**: Use arrow buttons for camera movement
   - **Up/Down**: Tilt camera vertically
   - **Left/Right**: Pan camera horizontally
   - **Home**: Return to preset position
2. **Zoom Controls**: 
   - **Zoom In**: Increase camera zoom level
   - **Zoom Out**: Decrease camera zoom level
3. **Touch Control**: Hold buttons for continuous movement, release to stop

### Tab 5: Audio & Recording
#### Audio Controls:
- **Enable/Mute Audio**: Toggle audio from live stream
- **Voice Talk**: Start two-way communication with device

#### Recording Controls:
- **Start/Stop Recording**: Record live video stream to device storage
- **Screenshot**: Capture current frame as image file

### Tab 6: WiFi Configuration
- **Coming Soon**: Device network setup and WiFi configuration features

## Code Structure

### Key Components

#### `NativeSDKDemoPage`
- Main demo interface with tabbed navigation
- SDK initialization and lifecycle management
- Device and player state management

#### `PTZControlPanel`
- Custom widget for PTZ camera controls
- Touch-based directional interface
- Real-time command execution

#### Native SDK Integration
```dart
// Initialize SDK
final options = EzvizInitOptions(
  appKey: appKey,
  accessToken: accessToken,
);
await EzvizManager.instance.initialize(options);

// Create Player
_playerController = EzvizPlayerController(
  deviceSerial: device.deviceSerial,
  cameraNo: device.cameraNo,
  verifyCode: verifyCode,
);

// PTZ Control
await EzvizManager.instance.controlMovement(
  deviceSerial,
  PTZCommand.up,
  PTZAction.start,
  speed: 4,
);

// Audio/Recording
await EzvizAudio.instance.startVoiceTalk(deviceSerial, cameraNo);
await EzvizRecording.instance.startRecording();
```

## Troubleshooting

### Common Issues

#### SDK Initialization Fails
- **Check credentials**: Verify App Key and App Secret are correct
- **Network connectivity**: Ensure device has internet access
- **Platform permissions**: Verify all required permissions are granted

#### Device List Empty
- **Account devices**: Ensure devices are added to your EZVIZ account
- **Device online status**: Check if devices are powered on and connected
- **Account binding**: Verify devices are properly bound to your account

#### Video Stream Issues
- **Verify code**: Enter correct verification code for encrypted devices
- **Network bandwidth**: Ensure sufficient bandwidth for video streaming
- **Device status**: Confirm device is online and accessible

#### PTZ Not Working
- **Device support**: Verify device supports PTZ functionality
- **Device permissions**: Ensure account has PTZ control permissions
- **Device binding**: Check device is properly associated with account

#### Audio/Recording Issues
- **Permissions**: Verify microphone and storage permissions
- **Device capabilities**: Confirm device supports audio features
- **Storage space**: Ensure sufficient device storage for recordings

### Error Codes
The app displays detailed error messages from the EZVIZ SDK. Common error codes include:
- **Authentication errors**: Invalid credentials or expired tokens
- **Device errors**: Device offline, invalid serial, or access denied
- **Network errors**: Connection timeout or network unavailable
- **Permission errors**: Insufficient account permissions or device access

## Development Notes

### SDK Features Utilized
- ✅ **EzvizManager**: Core SDK management and device operations
- ✅ **EzvizPlayerController**: Native video player with hardware acceleration
- ✅ **EzvizAudio**: Two-way audio and intercom functionality
- ✅ **EzvizRecording**: Video recording and screenshot capture
- ✅ **PTZ Controls**: Camera movement and zoom operations
- 🔄 **EzvizWiFiConfig**: Device network configuration (coming soon)

### Performance Optimizations
- **Hardware Acceleration**: Native video decoding for smooth playback
- **Memory Management**: Proper resource disposal and lifecycle handling
- **Async Operations**: Non-blocking UI with proper error handling
- **State Management**: Efficient state updates and UI synchronization

## Dependencies

```yaml
dependencies:
  ezviz_flutter: ^1.0.4          # Native EZVIZ SDK integration
  permission_handler: ^11.3.1    # Runtime permission management
  cupertino_icons: ^1.0.8       # iOS-style icons
  flutter_bloc: ^8.1.6          # State management (if needed)
```

## Contributing

This example app demonstrates the core capabilities of the ezviz_flutter package. For additional features or improvements:

1. **Fork the repository**
2. **Create feature branch**
3. **Implement changes with tests**
4. **Submit pull request with detailed description**

## License

This example application is provided under the same license as the parent ezviz_flutter package.

## Support

For issues related to:
- **EZVIZ SDK**: Contact EZVIZ developer support
- **Flutter Package**: Create issues on the GitHub repository
- **Example App**: Create issues with detailed error logs and reproduction steps

---

**Made with ❤️ for the Flutter Community**

Showcasing the power of native EZVIZ SDK integration in Flutter applications.
