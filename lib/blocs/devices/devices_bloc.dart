import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ezviz_example_app/repositories/ezviz_repository.dart'; // For Camera model and repository

part 'devices_event.dart';
part 'devices_state.dart';

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  final EzvizRepository _ezvizRepository;

  DevicesBloc({required EzvizRepository ezvizRepository})
      : _ezvizRepository = ezvizRepository,
        super(DevicesInitial()) {
    on<FetchDevices>(_onFetchDevices);
    on<RefreshDevices>(_onRefreshDevices);
    // Register other event handlers here if you add more events
  }

  Future<void> _onFetchDevices(
      FetchDevices event, Emitter<DevicesState> emit) async {
    emit(DevicesLoadInProgress());
    try {
      final cameras = await _ezvizRepository.getCameraList();
      print('DevicesBloc: Fetched ${cameras.length} cameras');
      emit(DevicesLoadSuccess(cameras: cameras));
    } catch (e) {
      print('DevicesBloc: Error loading cameras: ${e.toString()}');
      emit(DevicesLoadFailure(error: e.toString()));
    }
  }

  Future<void> _onRefreshDevices(
      RefreshDevices event, Emitter<DevicesState> emit) async {
    // Can be the same as fetching, or you might have different logic
    // for pull-to-refresh that doesn't show full loading indicator.
    // For now, treat it as a fresh fetch.
    emit(
        DevicesLoadInProgress()); // Or a different state like DevicesRefreshInProgress
    try {
      final cameras = await _ezvizRepository.getCameraList();
      print('DevicesBloc: Refreshed ${cameras.length} cameras');
      print('DevicesBloc: Got Data ${cameras.toString()} cameras');

      emit(DevicesLoadSuccess(cameras: cameras));
    } catch (e) {
      emit(DevicesLoadFailure(error: e.toString()));
    }
  }

  // Example for a future event handler:
  // Future<void> _onDeviceControlSent(DeviceControlSent event, Emitter<DevicesState> emit) async {
  //   try {
  //     // await _ezvizRepository.sendDeviceControl(event.deviceId, event.action);
  //     // Optionally, you might want to refresh the device list or a specific device's state
  //     // add(DevicesLoadRequested()); // Or a more specific event like DeviceStatusUpdateRequested
  //     print('Device control for ${event.deviceId} sent successfully.');
  //   } catch (e) {
  //     print('Error sending device control for ${event.deviceId}: ${e.toString()}');
  //     // Optionally emit a state to indicate failure of control command
  //     // emit(DeviceControlFailure(event.deviceId, e.toString()));
  //   }
  // }
}
