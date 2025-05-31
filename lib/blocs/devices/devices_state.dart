part of 'devices_bloc.dart';

abstract class DevicesState extends Equatable {
  const DevicesState();

  @override
  List<Object> get props => [];
}

// Initial state, before devices are loaded
class DevicesInitial extends DevicesState {}

// State when device list loading is in progress
class DevicesLoadInProgress extends DevicesState {}

// State when device list is successfully loaded
class DevicesLoadSuccess extends DevicesState {
  final List<Camera> cameras;

  const DevicesLoadSuccess({required this.cameras});

  // Backward compatibility: convert cameras to devices
  List<Device> get devices => cameras
      .map((camera) => Device(
            id: camera.id,
            name: camera.channelName,
            status: camera.status,
            thumbnailUrl: camera.thumbnailUrl,
          ))
      .toList();

  @override
  List<Object> get props => [cameras];
}

// State when device list loading fails
class DevicesLoadFailure extends DevicesState {
  final String error;

  const DevicesLoadFailure({required this.error});

  @override
  List<Object> get props => [error];
}
