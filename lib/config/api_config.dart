/// Optional configuration file for EZVIZ API credentials
///
/// This file is now OPTIONAL since the app uses UI-based authentication.
/// You can use this for development/testing convenience by pre-filling
/// the auth form, but it's not required for the app to work.
///
/// IMPORTANT:
/// - Do not commit real credentials to version control
/// - Use environment variables or secure storage for production apps
/// - The app will work without configuring anything here
class ApiConfig {
  // OPTIONAL: Pre-fill these for development convenience
  // Leave as empty strings if you want to enter credentials in the UI every time
  static const String developmentAppKey = '';
  static const String developmentAppSecret = '';

  // OPTIONAL: Use access token for direct authentication (bypasses App Key/Secret)
  static const String developmentAccessToken = '';

  // OPTIONAL: Encryption password for encrypted devices (if you have encrypted cameras)
  static const String developmentEncryptionPassword = '';

  // Example device serial for testing (optional)
  static const String exampleDeviceSerial = 'YOUR_DEVICE_SERIAL_HERE';

  // Helper to check if development credentials are set
  static bool get hasDevelopmentCredentials =>
      developmentAppKey.isNotEmpty && developmentAppSecret.isNotEmpty;

  // Helper to check if development access token is set
  static bool get hasDevelopmentAccessToken =>
      developmentAccessToken.isNotEmpty;

  // Helper to check if development encryption password is set
  static bool get hasDevelopmentEncryptionPassword =>
      developmentEncryptionPassword.isNotEmpty;
}
