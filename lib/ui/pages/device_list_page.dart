import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ezviz_example_app/blocs/auth/auth_bloc.dart';
import 'package:ezviz_example_app/blocs/devices/devices_bloc.dart';
import 'package:ezviz_example_app/ui/widgets/device_card.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<DevicesBloc>(context).add(FetchDevices());
  }

  Future<void> _onRefresh() async {
    BlocProvider.of<DevicesBloc>(context).add(RefreshDevices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My EZVIZ Devices'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              BlocProvider.of<AuthBloc>(context).add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<DevicesBloc, DevicesState>(
        listener: (context, state) {
          if (state is DevicesLoadFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                    content: Text('Failed to load devices: ${state.error}')),
              );
          }
        },
        builder: (context, state) {
          if (state is DevicesLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DevicesLoadSuccess) {
            if (state.cameras.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.no_meeting_room,
                        size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No cameras found.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      onPressed: _onRefresh,
                    )
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: state.cameras.length,
                itemBuilder: (context, index) {
                  final camera = state.cameras[index];
                  return DeviceCard(camera: camera);
                },
              ),
            );
          }

          if (state is DevicesLoadFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: _onRefresh,
                  ),
                ],
              ),
            );
          }

          // Initial state or unhandled state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Loading devices...'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Fetch Devices'),
                  onPressed: _onRefresh,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
