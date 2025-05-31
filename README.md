# EZVIZ Example App

A Flutter application demonstrating integration with EZVIZ cameras using the [ezviz_flutter](https://github.com/akshaynexus/ezviz_flutter) package.

## Features

- ✅ **UI-Based Authentication**: Enter your EZVIZ credentials directly in the app
- ✅ **Device Management**: List and manage EZVIZ cameras
- ✅ **Live Streaming**: View live camera feeds
- ✅ **Video Playback**: Access recorded video content
- ✅ **Modern UI**: Clean, responsive Material Design interface

## Prerequisites

Before running this app, you need:

1. **EZVIZ Developer Account**: Sign up at [EZVIZ Open Platform](https://open.ezviz.com/)
2. **API Credentials**: Obtain your App Key and App Secret from the platform
3. **EZVIZ Cameras**: Physical cameras registered to your account for testing

## Quick Start

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run the App

```bash
flutter run
```

### 3. Enter Your Credentials

When the app starts, you'll see a login screen where you can enter:
- **App Key**: Your EZVIZ application key
- **App Secret**: Your EZVIZ application secret

Get these credentials from the [EZVIZ Open Platform](https://open.ezviz.com/).

## Project Structure

```
lib/
├── config/
│   └── api_config.dart          # Optional development credentials
├── repositories/
│   └── ezviz_repository.dart    # EZVIZ API wrapper using ezviz_flutter
├── blocs/
│   ├── auth/                    # Authentication state management
│   └── devices/                 # Device list state management
├── ui/
│   └── pages/
│       ├── auth_page.dart       # Login/authentication screen
│       ├── device_list_page.dart # Camera list screen
│       └── video_player_page.dart # Live/playback video screen
└── main.dart                    # App entry point
```

## Key Features Explained

### Authentication
- **UI-Based Login**: Enter credentials directly in the app
- **No Configuration Required**: No need to modify code files
- **Secure**: Credentials are handled through the ezviz_flutter package
- **Optional Development Pre-fill**: Can optionally set development credentials in `api_config.dart`

### Device Management
- Fetches your camera list from EZVIZ cloud
- Displays device status (Online/Offline)
- Shows device thumbnails and names

### Video Streaming
- **Live View**: Real-time camera feeds using HLS protocol
- **Playback**: Historical video playback (1-hour window)
- **Controls**: Play/pause video controls

### State Management
Uses BLoC pattern for clean separation of business logic and UI:
- `AuthBloc`: Handles authentication state
- `DevicesBloc`: Manages device list and operations

## Dependencies

- **[ezviz_flutter](https://github.com/akshaynexus/ezviz_flutter)**: Core EZVIZ API integration
- **flutter_bloc**: State management
- **video_player**: Video playback functionality
- **equatable**: Value equality for state objects

## Development Setup (Optional)

For development convenience, you can pre-fill credentials in `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String developmentAppKey = 'your_dev_app_key';
  static const String developmentAppSecret = 'your_dev_app_secret';
}
```

⚠️ **Important**: Never commit real credentials to version control!

## Troubleshooting

### Authentication Failures
- Verify your App Key and App Secret are correct
- Check your EZVIZ account is active and has API access
- Ensure your network connection is stable

### No Devices Found
- Confirm you have EZVIZ cameras registered to your account
- Check that cameras are online and accessible
- Verify your account has proper permissions

### Video Streaming Issues
- Ensure cameras support live streaming
- Check network connectivity and bandwidth
- Some features may require specific camera models

## API Reference

The app uses the [ezviz_flutter package](https://github.com/akshaynexus/ezviz_flutter) which provides:

- `EzvizClient`: Core API client with authentication
- `DeviceService`: Device management operations
- `LiveService`: Live streaming URL generation
- `AuthService`: Authentication handling

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For issues related to:
- **This app**: Open an issue in this repository
- **ezviz_flutter package**: Visit the [package repository](https://github.com/akshaynexus/ezviz_flutter)
- **EZVIZ API**: Consult the [EZVIZ Open Platform documentation](https://open.ezviz.com/)

---

**Note**: This is a demo application for development and testing purposes. For production use, implement proper security measures, error handling, and user authentication.
