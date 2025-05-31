import 'package:flutter/material.dart';
import 'package:ezviz_example_app/repositories/ezviz_repository.dart'; // For Camera model
import 'package:ezviz_example_app/ui/pages/video_player_page.dart';

class DeviceCard extends StatelessWidget {
  final Camera camera;

  const DeviceCard({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    final bool isOnline = camera.isOnline;
    final Color statusColor = isOnline ? Colors.green : Colors.red;
    final IconData statusIcon = isOnline ? Icons.videocam : Icons.videocam_off;

    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VideoPlayerPage(camera: camera),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Thumbnail or Icon
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.grey[300],
                  image: camera.thumbnailUrl != null &&
                          camera.thumbnailUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(camera.thumbnailUrl!),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            // Optionally show a placeholder or error icon in the container
                            print('Error loading thumbnail: $exception');
                          },
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (camera.thumbnailUrl == null ||
                        camera.thumbnailUrl!.isEmpty)
                      Center(
                        child: Icon(Icons.camera_alt,
                            color: Colors.grey[600], size: 30),
                      ),
                    // Encryption indicator
                    if (camera.isEncrypt)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              // Camera Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      camera.channelName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4.0),
                        Text(
                          camera.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Device: ${camera.deviceSerial}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Channel: ${camera.channelNo}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    if (camera.isSharedCamera)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Shared',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Status and Action
              Column(
                children: [
                  if (camera.isEncrypt)
                    Tooltip(
                      message: 'Encrypted Camera',
                      child: Icon(
                        Icons.enhanced_encryption,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                    ),
                  const SizedBox(height: 8.0),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
