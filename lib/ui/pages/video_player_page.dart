import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // For RepositoryProvider
import 'package:ezviz_example_app/repositories/ezviz_repository.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final Camera camera;

  const VideoPlayerPage({super.key, required this.camera});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VlcPlayerController? _vlcController;
  bool _isLoadingStreamUrl = false;
  String? _currentStreamUrl;
  String? _error;
  bool _controllerInitialized = false; // Track initialization status

  @override
  void initState() {
    super.initState();
    _fetchAndInitializePlayer(
        isPlayback: false); // Fetch live stream by default
  }

  Future<void> _fetchAndInitializePlayer(
      {required bool isPlayback,
      DateTime? startTime,
      DateTime? endTime}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingStreamUrl = true;
      _error = null;
      _currentStreamUrl = null;
      // Safely dispose previous controller if any
      if (_vlcController != null && _controllerInitialized) {
        try {
          _vlcController!.dispose();
        } catch (disposeError) {
          print('Error disposing previous VLC controller: $disposeError');
        }
      }
      _vlcController = null;
      _controllerInitialized = false;
    });

    try {
      final repo =
          RepositoryProvider.of<EzvizRepository>(context, listen: false);
      String streamUrl;
      if (isPlayback) {
        if (startTime == null || endTime == null) {
          throw Exception('Start and End time required for playback');
        }
        streamUrl = await repo.getPlaybackUrl(
            widget.camera.deviceSerial, startTime, endTime);
      } else {
        streamUrl = await repo.getLiveStreamUrl(
          widget.camera.deviceSerial,
          channelNo: int.parse(widget.camera.channelNo),
        );
      }

      if (!mounted) return;
      setState(() {
        _currentStreamUrl = streamUrl;
      });

      // Wait for next frame to ensure the widget tree is ready
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      // Initialize VLC player with more robust error handling
      _vlcController = VlcPlayerController.network(
        streamUrl,
        hwAcc: HwAcc.auto, // Use auto instead of full for better compatibility
        autoPlay: false, // Set to false to prevent autoplay issues
        autoInitialize: false, // Manual initialization for better control
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(3000), // Increased caching
            VlcAdvancedOptions.clockJitter(0),
          ]),
          video: VlcVideoOptions([
            VlcVideoOptions.dropLateFrames(true),
            VlcVideoOptions.skipFrames(true),
          ]),
          sout: VlcStreamOutputOptions([
            VlcStreamOutputOptions.soutMuxCaching(3000),
          ]),
          rtp: VlcRtpOptions([
            VlcRtpOptions.rtpOverRtsp(true),
          ]),
        ),
      );

      // Manual initialization with error handling
      try {
        await _vlcController!.initialize();
        _controllerInitialized = true; // Mark as successfully initialized

        // Wait a bit more to ensure initialization is complete
        await Future.delayed(const Duration(milliseconds: 200));

        if (mounted && _vlcController != null) {
          // Now it's safe to start playback
          await _vlcController!.play();
          setState(() {}); // Update UI once controller is initialized
        }
      } catch (initError) {
        print('VLC initialization error: $initError');
        if (mounted) {
          setState(() {
            _error = 'Player initialization failed: ${initError.toString()}';
            // Only dispose if controller was actually initialized successfully
            if (_vlcController != null && _controllerInitialized) {
              try {
                _vlcController!.dispose();
              } catch (disposeError) {
                print('Error disposing VLC controller: $disposeError');
              }
            }
            _vlcController = null;
            _controllerInitialized = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      print('Failed to fetch stream URL: $e');
      setState(() {
        _error = 'Failed to load stream: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStreamUrl = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_vlcController != null && _controllerInitialized) {
      _vlcController?.dispose();
    }
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
                Theme.of(context).colorScheme.secondaryContainer
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _vlcController != null && !_isLoadingStreamUrl
                  ? VlcPlayer(
                      controller: _vlcController!,
                      aspectRatio: 16 / 9,
                      placeholder: const Center(
                          child: Text('Loading video...',
                              style: TextStyle(color: Colors.white))),
                    )
                  : _isLoadingStreamUrl
                      ? const Center(
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)),
                            SizedBox(height: 16),
                            Text('Loading stream...',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ))
                      : Center(
                          child: Text(
                            _error ?? 'Tap buttons below to load stream',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
            ),
          ),
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
                            : Colors.red),
                  ),
                  const SizedBox(height: 8),
                  if (_currentStreamUrl != null)
                    SelectableText('Stream URL: $_currentStreamUrl',
                        style: const TextStyle(fontSize: 12)),
                  if (_error != null &&
                      _currentStreamUrl ==
                          null) // Show error if URL fetch failed before player init
                    Text('Error: $_error',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error)),
                ],
              )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.live_tv),
                      label: const Text('Live View'),
                      onPressed: _isLoadingStreamUrl
                          ? null
                          : () => _fetchAndInitializePlayer(isPlayback: false),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(fontSize: 15)),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('Playback (1hr)'),
                      onPressed: _isLoadingStreamUrl
                          ? null
                          : () {
                              final endTime = DateTime.now();
                              final startTime =
                                  endTime.subtract(const Duration(hours: 1));
                              _fetchAndInitializePlayer(
                                  isPlayback: true,
                                  startTime: startTime,
                                  endTime: endTime);
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
