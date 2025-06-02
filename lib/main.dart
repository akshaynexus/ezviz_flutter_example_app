import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ezviz_example_app/ui/pages/auth_page.dart';
import 'package:ezviz_example_app/repositories/ezviz_repository.dart';
import 'package:ezviz_example_app/blocs/auth/auth_bloc.dart';
import 'package:ezviz_example_app/blocs/devices/devices_bloc.dart';
import 'package:ezviz_example_app/ui/pages/device_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EzvizRepository without credentials
  // Users will enter credentials through the UI
  final ezvizRepository = EzvizRepository();

  runApp(MyApp(ezvizRepository: ezvizRepository));
}

class MyApp extends StatelessWidget {
  final EzvizRepository ezvizRepository;

  const MyApp({super.key, required this.ezvizRepository});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [RepositoryProvider.value(value: ezvizRepository)],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(ezvizRepository: ezvizRepository)
                  ..add(AuthAppStarted()),
          ),
          BlocProvider<DevicesBloc>(
            create: (context) => DevicesBloc(ezvizRepository: ezvizRepository),
          ),
        ],
        child: MaterialApp(
          title: 'EZVIZ Example App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              titleLarge: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
              ),
              titleMedium: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
              ),
              bodyLarge: TextStyle(fontSize: 16.0),
              bodyMedium: TextStyle(fontSize: 14.0),
            ),
            appBarTheme: AppBarTheme(
              elevation: 2,
              centerTitle: true,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              titleTextStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthSuccess) {
                return const DeviceListPage();
              }
              return const AuthPage();
            },
          ),
        ),
      ),
    );
  }
}
