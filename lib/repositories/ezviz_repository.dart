import 'package:ezviz_flutter/ezviz_flutter.dart'; // Import your package

class EzvizRepository {
  EzvizClient? _client;
  AuthService? _authService;
  DeviceService? _deviceService;
  LiveService? _liveService;
  // Add other services as needed: AlarmService, PtzService, etc.

  String? _currentAppKey;
  String? _currentAppSecret;
  String? _currentAccessToken;
  String?
      _encryptionPassword; // Store encryption password for encrypted devices

  EzvizRepository();

  // Initialize the client and services with AppKey and AppSecret
  Future<void> initialize(
      {required String appKey, required String appSecret}) async {
    _currentAppKey = appKey;
    _currentAppSecret = appSecret;
    _currentAccessToken = null;
    _client = EzvizClient(appKey: appKey, appSecret: appSecret);
    _authService = AuthService(_client!);
    _deviceService = DeviceService(_client!);
    _liveService = LiveService(_client!);
    // Initialize other services here
    print('EzvizRepository initialized with AppKey: $appKey');
  }

  // Initialize with access token directly (new method)
  Future<void> initializeWithToken({required String accessToken}) async {
    _currentAccessToken = accessToken;
    _currentAppKey = null;
    _currentAppSecret = null;

    // Use the new EzvizClient constructor that supports access token directly
    _client = EzvizClient(accessToken: accessToken);

    _authService = AuthService(_client!);
    _deviceService = DeviceService(_client!);
    _liveService = LiveService(_client!);

    print(
        'EzvizRepository initialized with AccessToken: ${accessToken.substring(0, 10)}...');
  }

  // Login method - ensures the client is authenticated
  Future<bool> login() async {
    if (_authService == null) {
      throw Exception(
          'EzvizRepository not initialized. Call initialize() or initializeWithToken() first.');
    }

    // If we have an access token, skip the login process
    if (_currentAccessToken != null) {
      print('EzvizRepository: Using provided access token for authentication.');
      return true;
    }

    try {
      await _authService!.login();
      print('EzvizRepository: Login successful.');
      return true;
    } on EzvizAuthException catch (e) {
      print(
          'EzvizRepository: Login failed - EzvizAuthException: ${e.message} (Code: ${e.code})');
      return false;
    } on EzvizApiException catch (e) {
      print(
          'EzvizRepository: Login failed - EzvizApiException: ${e.message} (Code: ${e.code})');
      return false;
    } catch (e) {
      print('EzvizRepository: Login failed - Unexpected error: $e');
      return false;
    }
  }

  Future<List<Camera>> getCameraList() async {
    if (_deviceService == null) {
      throw Exception(
          'EzvizRepository not initialized. Call initialize() first.');
    }
    try {
      print('About to call DeviceService.getCameraList()...');

      try {
        final response = await _deviceService!.getCameraList(pageSize: 50);
        print('getCameraList call completed successfully');
        print('Response: ${response.toString()}');

        // Handle both string and integer response codes
        final responseCode = response['code']?.toString() ?? '';
        if ((responseCode == '200' || response['code'] == 200) &&
            response['data'] != null) {
          final cameraDataList = response['data'] as List<dynamic>;
          print('Found ${cameraDataList.length} cameras');

          return cameraDataList.map((data) {
            return Camera(
              deviceSerial:
                  data['deviceSerial']?.toString() ?? 'Unknown Serial',
              channelNo: data['channelNo']?.toString() ?? '1',
              channelName: data['channelName']?.toString() ?? 'Unknown Camera',
              status: (data['status'] == 1 || data['status'] == '1')
                  ? 'Online'
                  : 'Offline',
              isShared: data['isShared']?.toString() ?? '0',
              thumbnailUrl: data['picUrl']?.toString() ?? '',
              isEncrypt: (data['isEncrypt'] == 1 || data['isEncrypt'] == '1'),
              videoLevel: data['videoLevel']?.toString() ?? '2',
            );
          }).toList();
        } else {
          print(
              'API Error - Code: ${response['code']}, Message: ${response['msg']}');
          return [];
        }
      } catch (e) {
        print('Error in DeviceService.getCameraList(): $e');
        if (e.toString().contains('int\' is not a subtype of type \'String')) {
          print(
              'Known type casting error in ezviz_flutter package - returning empty list');
          return []; // Return empty list to prevent crash
        }
        rethrow;
      }
    } catch (e) {
      print('Error fetching camera list: $e');
      return []; // Return empty list instead of crashing
    }
  }

  // Keep the old method for backward compatibility but mark as deprecated
  @Deprecated('Use getCameraList() instead for better camera information')
  Future<List<Device>> getDeviceList() async {
    // Convert cameras to devices for backward compatibility
    final cameras = await getCameraList();
    return cameras
        .map((camera) => Device(
              id: camera.id,
              name: camera.channelName,
              status: camera.status,
              thumbnailUrl: camera.thumbnailUrl,
            ))
        .toList();
  }

  Future<String> getLiveStreamUrl(String deviceSerial,
      {int channelNo = 1}) async {
    if (_liveService == null) {
      throw Exception(
          'EzvizRepository not initialized. Call initialize() first.');
    }
    try {
      Map<String, dynamic> response;
      String? workingUrl;

      // List of protocols to try (in order of preference for VLC compatibility)
      // 1-ezopen (NOT VLC compatible), 2-hls, 3-rtmp, 4-flv
      final protocols = [
        2, // HLS (HTTP Live Streaming) - best for VLC and mobile
        3, // RTMP - good VLC compatibility
        4, // FLV - also works with VLC
        // Note: We skip protocol 1 (ezopen) as it's not VLC compatible
      ];

      for (int protocol in protocols) {
        try {
          String protocolName = protocol == 2
              ? 'HLS'
              : protocol == 3
                  ? 'RTMP'
                  : protocol == 4
                      ? 'FLV'
                      : 'Unknown';
          print(
              'Trying protocol $protocol ($protocolName) for device: $deviceSerial');
          print('Encryption Password: $_encryptionPassword');
          print(
              'Encrypton password is not null: ${_encryptionPassword != null}');
          // Use the new password-enabled method if encryption password is set
          if (_encryptionPassword != null) {
            print('Using encryption password for device: $deviceSerial');

            // First, let's check device encryption details
            await checkDeviceEncryption(deviceSerial);

            print('Testing direct getPlayAddress with code parameter:');
            print('  - deviceSerial: $deviceSerial');
            print('  - code: $_encryptionPassword');
            print('  - password: $_encryptionPassword');
            print('  - channelNo: $channelNo');
            print('  - protocol: $protocol');
            print('  - quality: 1');

            response = await _liveService!.getPlayAddressWithPassword(
              deviceSerial,
              _encryptionPassword ?? '',
              channelNo: channelNo,
              protocol: protocol,
              quality: 1, // HD quality for better VLC compatibility
            );
          } else {
            print('No encryption password set, calling without code parameter');
            // Try without password first, will automatically retry with password if needed
            response = await _liveService!.getPlayAddress(
              deviceSerial,
              channelNo: channelNo,
              protocol: protocol,
              quality: 1, // HD quality for better VLC compatibility
              // Do NOT pass password parameter when it's null
            );
          }

          // Handle both string and integer response codes
          final responseCode = response['code']?.toString() ?? '';
          if ((responseCode == '200' || response['code'] == 200) &&
              response['data'] != null &&
              response['data']['url'] != null) {
            final url = response['data']['url'].toString();
            print(response.toString());
            print(
                'Got VLC-compatible URL with protocol $protocol ($protocolName): $url');

            // Since we only request VLC-compatible protocols, any URL should work
            workingUrl = url;
            print('Successfully got $protocolName stream URL: $workingUrl');
            break;
          }
        } catch (protocolError) {
          print('Protocol $protocol failed: $protocolError');
          print('Full error details: ${protocolError.toString()}');
          continue;
        }
      }

      if (workingUrl != null) {
        return workingUrl;
      } else {
        throw Exception(
            'Failed to get VLC-compatible stream URL for device $deviceSerial. '
            'Tried protocols: HLS, RTMP, FLV. Check device connectivity and permissions.');
      }
    } catch (e) {
      print('Error fetching live stream URL for $deviceSerial: $e');
      rethrow;
    }
  }

  // Convenience method for Camera objects
  Future<String> getLiveStreamUrlForCamera(Camera camera) async {
    return getLiveStreamUrl(
      camera.deviceSerial,
      channelNo: int.parse(camera.channelNo),
    );
  }

  Future<String> getPlaybackUrl(
      String deviceSerial, DateTime startTime, DateTime endTime,
      {int channelNo = 1}) async {
    if (_liveService == null) {
      throw Exception(
          'EzvizRepository not initialized. Call initialize() first.');
    }

    try {
      // For playback, we'll use the live service but with different parameters
      // Note: The actual ezviz_flutter package might have specific playback methods
      // For now, we'll use the live stream as a fallback and add a note
      print(
          'Fetching playback URL for device: $deviceSerial from ${startTime.toIso8601String()} to ${endTime.toIso8601String()}');

      // Try to get a live stream URL as fallback since specific playback URL
      // method might need to be implemented in the ezviz_flutter package
      final response = await _liveService!.getPlayAddress(
        deviceSerial,
        channelNo: channelNo,
        protocol: 3,
        quality: 1,
        password: _encryptionPassword, // Use encryption password if available
      );

      // Handle both string and integer response codes
      final responseCode = response['code']?.toString() ?? '';
      if ((responseCode == '200' || response['code'] == 200) &&
          response['data'] != null &&
          response['data']['url'] != null) {
        // For now, return the live URL with a warning
        print(
            'Warning: Using live stream URL as playback URL. Specific playback API may need implementation.');
        return response['data']['url'].toString();
      } else {
        throw Exception(
            'Failed to get playback URL (Code: ${response['code']}, Message: ${response['msg']})');
      }
    } catch (e) {
      print('Error fetching playback URL for $deviceSerial: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    // Clear local client and service instances
    _client = null;
    _authService = null;
    _deviceService = null;
    _liveService = null;
    _currentAppKey = null;
    _currentAppSecret = null;
    // If your ezviz_flutter package has a specific SDK logout or token invalidation method, call it here.
    // e.g., await _client?.invalidateToken(); or await _authService?.logout();
    print('EzvizRepository: Logged out, client data cleared.');
  }

  // Getter for checking if repository is initialized
  bool get isInitialized => _client != null;

  // Getters for app credentials (useful for debugging)
  String? get currentAppKey => _currentAppKey;
  String? get currentAppSecret => _currentAppSecret;

  // Set encryption password for encrypted devices
  void setEncryptionPassword(String password) {
    _encryptionPassword = password;
    print('EzvizRepository: Encryption password set for encrypted devices');
  }

  // Method to check device encryption status and info
  Future<void> checkDeviceEncryption(String deviceSerial) async {
    if (_deviceService == null) return;

    try {
      print('=== DEVICE ENCRYPTION DEBUG ===');
      print('Checking device info for: $deviceSerial');

      // Get device detailed info
      final deviceInfo = await _deviceService!.getDeviceInfo(deviceSerial);
      print('Device Info Response: ${deviceInfo.toString()}');

      // Try to get device status
      final deviceStatus = await _deviceService!.getDeviceStatus(deviceSerial);
      print('Device Status Response: ${deviceStatus.toString()}');

      // Check if device requires verification code
      if (deviceInfo['data'] != null && deviceInfo['data']['isEncrypt'] == 1) {
        print('🔒 Device is ENCRYPTED - requires verification code');
        print('Current encryption password: $_encryptionPassword');

        // Try to get device verification info if available
        try {
          print('Attempting to get device verification requirements...');
          // This might not exist in the API, but worth trying
          final verifyInfo = await _deviceService!.getDeviceInfo(deviceSerial);
          if (verifyInfo['data'] != null) {
            print('Device verification info: ${verifyInfo['data']}');
          }
        } catch (e) {
          print('Could not get verification info: $e');
        }
      } else {
        print('🔓 Device is NOT encrypted');
      }
    } catch (e) {
      print('Error checking device encryption: $e');
    }
  }

  // Add other methods to interact with your package as needed.
}

// Device model class
class Device {
  final String id;
  final String name;
  final String status;
  final String? thumbnailUrl;

  Device({
    required this.id,
    required this.name,
    required this.status,
    this.thumbnailUrl,
  });

  @override
  String toString() {
    return 'Device(id: $id, name: $name, status: $status)';
  }
}

// Camera model class - more detailed than Device
class Camera {
  final String deviceSerial;
  final String channelNo;
  final String channelName;
  final String status;
  final String isShared;
  final String? thumbnailUrl;
  final bool isEncrypt;
  final String videoLevel;

  Camera({
    required this.deviceSerial,
    required this.channelNo,
    required this.channelName,
    required this.status,
    required this.isShared,
    this.thumbnailUrl,
    required this.isEncrypt,
    required this.videoLevel,
  });

  // Helper method to get unique camera ID
  String get id => '${deviceSerial}_$channelNo';

  // Helper method to check if camera is online
  bool get isOnline => status.toLowerCase() == 'online';

  // Helper method to check if camera is shared
  bool get isSharedCamera => isShared == '1';

  @override
  String toString() {
    return 'Camera(deviceSerial: $deviceSerial, channelNo: $channelNo, channelName: $channelName, status: $status, isEncrypt: $isEncrypt)';
  }
}
