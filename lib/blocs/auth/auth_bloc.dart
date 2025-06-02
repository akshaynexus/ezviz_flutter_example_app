import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ezviz_example_app/repositories/ezviz_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final EzvizRepository _ezvizRepository;
  // You might want to persist the token using flutter_secure_storage or shared_preferences
  // final TokenStorage _tokenStorage;

  AuthBloc({required EzvizRepository ezvizRepository})
    : _ezvizRepository = ezvizRepository,
      // _tokenStorage = tokenStorage,
      super(AuthInitial()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthCredentialsSubmitted>(_onCredentialsSubmitted);
    on<AuthTokenSubmitted>(_onTokenSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(
    AuthAppStarted event,
    Emitter<AuthState> emit,
  ) async {
    // Since we're now using UI-based authentication,
    // we start with AuthInitial to show the login page
    emit(AuthInitial());
  }

  Future<void> _onCredentialsSubmitted(
    AuthCredentialsSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Initialize the repository with user-provided credentials
      await _ezvizRepository.initialize(
        appKey: event.appKey,
        appSecret: event.appSecret,
      );

      // Set encryption password if provided
      if (event.encryptionPassword != null) {
        _ezvizRepository.setEncryptionPassword(event.encryptionPassword!);
      }

      final bool loginSuccess = await _ezvizRepository.login();

      if (loginSuccess) {
        print('AuthBloc: Login successful with AppKey: ${event.appKey}');
        emit(AuthSuccess(appKey: event.appKey));
      } else {
        print('AuthBloc: Login failed by repository.');
        emit(const AuthFailure('Invalid credentials or login failed.'));
      }
    } catch (e) {
      print('AuthBloc: Login error: ${e.toString()}');
      emit(AuthFailure('An error occurred during login: ${e.toString()}'));
    }
  }

  Future<void> _onTokenSubmitted(
    AuthTokenSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Initialize the repository with access token and appKey
      await _ezvizRepository.initializeWithToken(
        accessToken: event.accessToken,
        appKey: event.appKey,
      );

      // Set encryption password if provided
      if (event.encryptionPassword != null) {
        _ezvizRepository.setEncryptionPassword(event.encryptionPassword!);
      }

      final bool loginSuccess = await _ezvizRepository.login();

      if (loginSuccess) {
        print(
          'AuthBloc: Login successful with AccessToken: ${event.accessToken.substring(0, 10)}... and AppKey: ${event.appKey.substring(0, 8)}...',
        );
        emit(
          AuthSuccess(appKey: event.appKey),
        ); // Use the actual appKey instead of placeholder
      } else {
        print('AuthBloc: Login failed by repository.');
        emit(const AuthFailure('Invalid access token or login failed.'));
      }
    } catch (e) {
      print('AuthBloc: Login error: ${e.toString()}');
      emit(
        AuthFailure('An error occurred during token login: ${e.toString()}'),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _ezvizRepository.logout();
      print('AuthBloc: Logout successful.');
      emit(AuthLoggedOut());
    } catch (e) {
      print('AuthBloc: Logout error: ${e.toString()}');
      emit(AuthLoggedOut());
    }
  }
}
