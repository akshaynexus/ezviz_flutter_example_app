part of 'devices_bloc.dart';

// import 'package:equatable/equatable.dart'; // Removed from here

abstract class DevicesEvent extends Equatable {
  const DevicesEvent();

  @override
  List<Object> get props => [];
}

// Event to request loading the device list
class FetchDevices extends DevicesEvent {}

// If you need to refresh the list
class RefreshDevices extends DevicesEvent {}

// You could add events for specific device actions later if needed
// e.g., class ToggleDeviceStatus extends DevicesEvent { ... }

// You might add more events later, e.g., for a specific device action
// class DeviceControlSent extends DevicesEvent {
//   final String deviceId;
//   final DeviceControlAction action;
//   const DeviceControlSent(this.deviceId, this.action);
//   @override
//   List<Object> get props => [deviceId, action];
// }
