part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// Initial state, before any authentication attempt
class AuthInitial extends AuthState {}

// State when authentication is in progress
class AuthLoading extends AuthState {}

// State when authentication is successful
class AuthSuccess extends AuthState {
  final String
      appKey; // Store appKey to indicate successful login with these credentials

  const AuthSuccess({required this.appKey});

  @override
  List<Object> get props => [appKey];
}

// State when authentication fails
class AuthFailure extends AuthState {
  final String error;

  const AuthFailure(this.error);

  @override
  List<Object> get props => [error];
}

// State when user is logged out (can be same as AuthInitial or distinct)
class AuthLoggedOut extends AuthState {}
