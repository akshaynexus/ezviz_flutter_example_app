part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Event triggered when the app starts to check initial auth state
class AuthAppStarted extends AuthEvent {}

// Event triggered when appKey and appSecret are submitted
class AuthCredentialsSubmitted extends AuthEvent {
  final String appKey;
  final String appSecret;
  final String? encryptionPassword; // Optional password for encrypted devices

  const AuthCredentialsSubmitted(
    this.appKey,
    this.appSecret, {
    this.encryptionPassword,
  });

  @override
  List<Object?> get props => [appKey, appSecret, encryptionPassword];
}

// Event triggered when access token is submitted
class AuthTokenSubmitted extends AuthEvent {
  final String accessToken;
  final String appKey; // AppKey is required for native SDK initialization
  final String? encryptionPassword; // Optional password for encrypted devices

  const AuthTokenSubmitted(
    this.accessToken,
    this.appKey, {
    this.encryptionPassword,
  });

  @override
  List<Object?> get props => [accessToken, appKey, encryptionPassword];
}

// Event triggered for logout
class AuthLogoutRequested extends AuthEvent {}
