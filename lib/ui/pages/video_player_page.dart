import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // For RepositoryProvider
import 'package:ezviz_example_app/repositories/ezviz_repository.dart';
import 'package:ezviz_example_app/ui/widgets/encryption_password_dialog.dart';
import 'package:ezviz_example_app/services/encryption_storage_service.dart';
import 'package:ezviz_flutter/ezviz_flutter.dart';

class VideoPlayerPage extends StatefulWidget {
  final Camera camera;

  const VideoPlayerPage({super.key, required this.camera});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  EzvizPlayerController? _playerController;
  bool _isPlaying = false;
  bool _isRecording = false;
  bool _soundEnabled = false;
  bool _isLoadingPlayer = false;
  String? _error;
  String? _encryptionPassword;
  bool _isRequestingPassword = false;
  final EncryptionStorageService _encryptionStorage = EncryptionStorageService();

  @override
  void initState() {
    super.initState();
    _setupEventHandlers();
  }

  void _setupEventHandlers() {
    EzvizManager.shared().setEventHandler(
      (EzvizEvent event) {
        ezvizLog('Global Event received: ${event.eventType}');
        ezvizLog('Message: ${event.msg}');
      },
      (error) {
        ezvizLog('Global Event Error: $error');
      },
    );
  }

  void _setupPlayerEventHandlers() {
    if (_playerController != null) {
      _playerController!.setPlayerEventHandler(
        (EzvizEvent event) {
          ezvizLog('Player Event received: ${event.eventType}');
          ezvizLog('Message: ${event.msg}');

          if (event.eventType == EzvizChannelEvents.playerStatusChange) {
            ezvizLog('Raw event data: ${event.data}');
            if (event.data is EzvizPlayerStatus) {
              final status = event.data as EzvizPlayerStatus;
              ezvizLog('Player Status: ${status.status}');
              
              if (mounted) {
                setState(() {
                  // Update playing state
                  _isPlaying = status.status == 2; // 2 = Start/Playing state
                  
                  // Clear loading state when player is initialized or playing
                  if (status.status == 1 || status.status == 2) { // 1 = Init, 2 = Start
                    _isLoadingPlayer = false;
                  }
                  
                  // Handle errors
                  if (status.status == 5 && status.message != null) { // 5 = Error state
                    _isLoadingPlayer = false;
                    final errorMsg = status.message!.toLowerCase();
                    if (errorMsg.contains('password') || 
                        errorMsg.contains('verification') ||
                        errorMsg.contains('encrypt') ||
                        errorMsg.contains('verify')) {
                      ezvizLog('Detected encryption error: ${status.message}');
                      _error = 'Verification code error. Please check your password.';
                      // Handle encryption error in background
                      Future.delayed(Duration.zero, () => _handleEncryptionError());
                      return;
                    } else {
                      _error = status.message;
                    }
                  }
                });
              }
              
              if (status.message != null) {
                ezvizLog('Status Message: ${status.message}');
              }
            } else {
              ezvizLog('Failed to parse player status data: ${event.data}');
            }
          }
        },
        (error) {
          ezvizLog('Player Event Error: $error');
          if (mounted) {
            setState(() {
              _error = 'Player error: $error';
            });
          }
        },
      );
    }
  }

  Future<void> _initializePlayer() async {
    if (_playerController != null) {
      setState(() {
        _isLoadingPlayer = true;
        _error = null;
      });

      try {
        // Ensure SDK is initialized before creating player
        final repo = RepositoryProvider.of<EzvizRepository>(
          context,
          listen: false,
        );

        // Debug: Check current SDK status
        await repo.checkSDKStatus();

        // Check if SDK is properly initialized
        if (!repo.isInitialized) {
          throw Exception('SDK not initialized. Please login first.');
        }

        if (!repo.hasCredentials) {
          throw Exception('No credentials available for SDK initialization.');
        }

        // Re-initialize the SDK to ensure it's ready for player operations
        ezvizLog('Re-initializing SDK before player creation...');
        final sdkInitialized = await repo.initializeSDK();
        if (!sdkInitialized) {
          throw Exception('Failed to initialize native SDK');
        }

        ezvizLog('SDK successfully initialized, creating player...');
        ezvizLog(
          'Device: ${widget.camera.deviceSerial}, Channel: ${widget.camera.channelNo}',
        );

        await _playerController!.initPlayerByDevice(
          widget.camera.deviceSerial,
          int.parse(widget.camera.channelNo),
        );

        // Set verify code if the camera is encrypted
        if (widget.camera.isEncrypt) {
          ezvizLog('Camera is encrypted, handling verification code...');
          
          // Check if we have a stored password
          String? password = _encryptionStorage.getPassword(widget.camera.deviceSerial);
          
          if (password == null && _encryptionPassword == null) {
            // No stored password, need to request from user
            password = await _requestEncryptionPassword();
            if (password == null) {
              throw Exception('Verification code required for encrypted camera');
            }
          } else if (_encryptionPassword != null) {
            password = _encryptionPassword;
          }
          
          if (password != null) {
            ezvizLog('Setting verification code for encrypted camera');
            await _playerController!.setPlayVerifyCode(password);
            _encryptionPassword = password;
          }
        }

        ezvizLog(
          'Player initialized successfully for device: ${widget.camera.deviceSerial}',
        );
      } catch (e) {
        ezvizLog('Error initializing player: $e');
        setState(() {
          _error = 'Failed to initialize player: $e';
        });
      } finally {
        setState(() {
          _isLoadingPlayer = false;
        });
      }
    }
  }

  Future<void> _startLiveStream() async {
    if (_playerController == null) return;

    try {
      final success = await _playerController!.startRealPlay();
      if (success) {
        setState(() {
          _isPlaying = true;
          _error = null;
        });
        ezvizLog('Live stream started successfully');
      } else {
        // Check if this is an encrypted camera and we need password
        if (widget.camera.isEncrypt && _encryptionPassword == null) {
          ezvizLog('Live stream failed - might need encryption password');
          await _handleEncryptionError();
        } else {
          setState(() {
            _error = 'Failed to start live stream';
          });
        }
      }
    } catch (e) {
      ezvizLog('Error starting live stream: $e');
      
      // Check if error is related to encryption
      final errorStr = e.toString().toLowerCase();
      if (widget.camera.isEncrypt && 
          (errorStr.contains('password') || 
           errorStr.contains('verification') ||
           errorStr.contains('encrypt'))) {
        await _handleEncryptionError();
      } else {
        setState(() {
          _error = 'Error starting live stream: $e';
        });
      }
    }
  }

  Future<void> _stopLiveStream() async {
    if (_playerController == null) return;

    try {
      final success = await _playerController!.stopRealPlay();
      if (success) {
        setState(() {
          _isPlaying = false;
        });
        ezvizLog('Live stream stopped successfully');
      }
    } catch (e) {
      ezvizLog('Error stopping live stream: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _stopLiveStream();
    } else {
      await _startLiveStream();
    }
  }

  Future<void> _toggleSound() async {
    if (_playerController == null) return;

    try {
      bool success;
      if (_soundEnabled) {
        success = await _playerController!.closeSound();
      } else {
        success = await _playerController!.openSound();
      }

      if (success) {
        setState(() {
          _soundEnabled = !_soundEnabled;
        });
      }
    } catch (e) {
      ezvizLog('Error toggling sound: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_playerController == null) return;

    try {
      bool success;
      if (_isRecording) {
        success = await _playerController!.stopRecording();
      } else {
        success = await _playerController!.startRecording();
      }

      if (success && mounted) {
        setState(() {
          _isRecording = !_isRecording;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isRecording ? 'Recording started' : 'Recording stopped',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording feature not available in current SDK version'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      ezvizLog('Error toggling recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording failed: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _takeScreenshot() async {
    if (_playerController == null) return;

    try {
      final imagePath = await _playerController!.capturePicture();
      if (imagePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot saved: $imagePath'),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Screenshot feature not available in current SDK version'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      ezvizLog('Error taking screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot failed: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _startPlayback() async {
    if (_playerController == null) return;

    try {
      final endTime = DateTime.now();
      final startTime = endTime.subtract(const Duration(hours: 1));

      final success = await _playerController!.startReplay(startTime, endTime);
      if (success) {
        setState(() {
          _isPlaying = true;
          _error = null;
        });
        ezvizLog('Playback started successfully');
      } else {
        setState(() {
          _error = 'Failed to start playback';
        });
      }
    } catch (e) {
      ezvizLog('Error starting playback: $e');
      setState(() {
        _error = 'Error starting playback: $e';
      });
    }
  }

  /// Request encryption password from user
  Future<String?> _requestEncryptionPassword() async {
    if (_isRequestingPassword) return null; // Prevent multiple dialogs
    
    setState(() {
      _isRequestingPassword = true;
    });

    try {
      final result = await showEncryptionPasswordDialog(
        context,
        cameraName: widget.camera.channelName,
        deviceSerial: widget.camera.deviceSerial,
      );

      if (result != null && result['password'] != null) {
        final password = result['password'] as String;
        final remember = result['remember'] as bool? ?? false;

        if (remember) {
          _encryptionStorage.storePassword(widget.camera.deviceSerial, password);
        }

        return password;
      }
    } catch (e) {
      ezvizLog('Error requesting encryption password: $e');
    } finally {
      setState(() {
        _isRequestingPassword = false;
      });
    }

    return null;
  }

  /// Handle encryption errors and retry
  Future<void> _handleEncryptionError() async {
    // Remove any stored password as it might be incorrect
    _encryptionStorage.removePassword(widget.camera.deviceSerial);
    _encryptionPassword = null;

    // Request new password
    final password = await _requestEncryptionPassword();
    if (password != null) {
      _encryptionPassword = password;
      // Retry initialization
      await _initializePlayer();
    }
  }

  /// Handle encryption settings (change password)
  Future<void> _handleEncryptionSettings() async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.enhanced_encryption, color: Colors.amber),
              SizedBox(width: 8),
              Text('Encryption Settings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Camera: ${widget.camera.channelName}'),
              const SizedBox(height: 8),
              Text('Device: ${widget.camera.deviceSerial}'),
              const SizedBox(height: 16),
              if (_encryptionPassword != null)
                const Text('✓ Verification code is set')
              else
                const Text('⚠ No verification code set'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (_encryptionPassword != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop('clear'),
                child: const Text('Clear Password'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('change'),
              child: Text(_encryptionPassword != null ? 'Change Password' : 'Set Password'),
            ),
          ],
        );
      },
    );

    if (result == 'clear') {
      _encryptionStorage.removePassword(widget.camera.deviceSerial);
      setState(() {
        _encryptionPassword = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code cleared')),
        );
      }
    } else if (result == 'change') {
      final password = await _requestEncryptionPassword();
      if (password != null && _playerController != null) {
        await _playerController!.setPlayVerifyCode(password);
        setState(() {
          _encryptionPassword = password;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification code updated')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _playerController?.stopRealPlay();
    _playerController?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.camera.channelName),
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // EZVIZ Player Widget
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _isLoadingPlayer
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Initializing player...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : EzvizPlayer(
                      onCreated: (controller) {
                        _playerController = controller;
                        _setupPlayerEventHandlers();
                        _initializePlayer();
                      },
                    ),
            ),
          ),

          // Device Status and Error Display
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Status: ${widget.camera.status}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.camera.status.toLowerCase() == 'online'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.camera.isEncrypt)
                  const Text(
                    '🔒 This camera is encrypted',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                if (_error != null)
                  Text(
                    'Error: $_error',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // Enhanced Controls
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(_isPlaying ? 'Pause' : 'Live'),
                      onPressed: _togglePlayPause,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('Playback'),
                      onPressed: _startPlayback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Additional Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        _soundEnabled ? Icons.volume_up : Icons.volume_off,
                      ),
                      onPressed: _toggleSound,
                      tooltip: 'Toggle Sound',
                      color: _soundEnabled ? Colors.blue : Colors.grey,
                    ),
                    IconButton(
                      icon: Icon(
                        _isRecording ? Icons.stop : Icons.fiber_manual_record,
                      ),
                      onPressed: _toggleRecording,
                      tooltip: 'Toggle Recording',
                      color: _isRecording ? Colors.red : Colors.grey,
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _takeScreenshot,
                      tooltip: 'Take Screenshot',
                      color: Colors.grey,
                    ),
                    if (widget.camera.isEncrypt)
                      IconButton(
                        icon: Icon(
                          _encryptionPassword != null 
                              ? Icons.enhanced_encryption 
                              : Icons.lock_open,
                        ),
                        onPressed: _handleEncryptionSettings,
                        tooltip: 'Encryption Settings',
                        color: _encryptionPassword != null 
                            ? Colors.green 
                            : Colors.amber,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
