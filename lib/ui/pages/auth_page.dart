import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ezviz_example_app/blocs/auth/auth_bloc.dart';
import 'package:ezviz_example_app/config/api_config.dart';
// import 'package:ezviz_example_app/ui/pages/device_list_page.dart'; // Navigation is handled by main.dart

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _appKeyController = TextEditingController();
  final _appSecretController = TextEditingController();
  final _accessTokenController = TextEditingController();
  final _encryptionPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _useAccessToken = true; // Default to access token mode
  bool _hasEncryptedDevices = false; // Toggle for encryption password

  @override
  void initState() {
    super.initState();
    // Pre-fill with development credentials if available (for convenience)
    if (ApiConfig.hasDevelopmentCredentials) {
      _appKeyController.text = ApiConfig.developmentAppKey;
      _appSecretController.text = ApiConfig.developmentAppSecret;
    }

    // Pre-fill access token if available and switch to token mode
    if (ApiConfig.hasDevelopmentAccessToken) {
      _accessTokenController.text = ApiConfig.developmentAccessToken;
      _useAccessToken = true;
    }

    // Pre-fill encryption password if available and enable encrypted devices toggle
    if (ApiConfig.hasDevelopmentEncryptionPassword) {
      _encryptionPasswordController.text =
          ApiConfig.developmentEncryptionPassword;
      _hasEncryptedDevices = true;
    }
  }

  @override
  void dispose() {
    _appKeyController.dispose();
    _appSecretController.dispose();
    _accessTokenController.dispose();
    _encryptionPasswordController.dispose();
    super.dispose();
  }

  void _submitCredentials() {
    if (_formKey.currentState!.validate()) {
      final encryptionPassword =
          _hasEncryptedDevices && _encryptionPasswordController.text.isNotEmpty
          ? _encryptionPasswordController.text
          : null;

      if (_useAccessToken) {
        final accessToken = _accessTokenController.text;
        final appKey = _appKeyController.text;
        BlocProvider.of<AuthBloc>(context).add(
          AuthTokenSubmitted(
            accessToken,
            appKey,
            encryptionPassword: encryptionPassword,
          ),
        );
      } else {
        final appKey = _appKeyController.text;
        final appSecret = _appSecretController.text;
        BlocProvider.of<AuthBloc>(context).add(
          AuthCredentialsSubmitted(
            appKey,
            appSecret,
            encryptionPassword: encryptionPassword,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EZVIZ Login'),
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
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('Login Failed: ${state.error}')),
              );
          }
          // AuthSuccess navigation is handled by BlocBuilder in main.dart
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Welcome to EZVIZ Example',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _useAccessToken
                            ? 'Enter your EZVIZ App Key and Access Token'
                            : 'Enter your EZVIZ App Key and App Secret',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _useAccessToken
                            ? 'Use an existing access token with your app key for authentication'
                            : 'Get your credentials from the EZVIZ Open Platform',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Toggle between authentication methods
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _useAccessToken
                                    ? 'Using Access Token'
                                    : 'Using App Key/Secret',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Switch(
                                value: _useAccessToken,
                                onChanged: (value) {
                                  setState(() {
                                    _useAccessToken = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Show appropriate form fields based on authentication mode
                      if (_useAccessToken) ...[
                        TextFormField(
                          controller: _appKeyController,
                          decoration: const InputDecoration(
                            labelText: 'App Key',
                            hintText: 'Enter your EZVIZ App Key',
                            prefixIcon: Icon(Icons.key),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'App Key is required for native SDK initialization';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accessTokenController,
                          decoration: const InputDecoration(
                            labelText: 'Access Token',
                            hintText: 'Enter your EZVIZ Access Token',
                            prefixIcon: Icon(Icons.token),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Access Token cannot be empty';
                            }
                            return null;
                          },
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _appKeyController,
                          decoration: const InputDecoration(
                            labelText: 'App Key',
                            hintText: 'Enter your EZVIZ App Key',
                            prefixIcon: Icon(Icons.vpn_key),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'App Key cannot be empty';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _appSecretController,
                          decoration: const InputDecoration(
                            labelText: 'App Secret',
                            hintText: 'Enter your EZVIZ App Secret',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'App Secret cannot be empty';
                            }
                            return null;
                          },
                          obscureText: true,
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Encryption password section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Encrypted Devices',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Enable if you have encrypted cameras',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _hasEncryptedDevices,
                                    onChanged: (value) {
                                      setState(() {
                                        _hasEncryptedDevices = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_hasEncryptedDevices) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _encryptionPasswordController,
                                  decoration: const InputDecoration(
                                    labelText: 'Encryption Password',
                                    hintText:
                                        'Enter your device encryption password',
                                    prefixIcon: Icon(Icons.security),
                                    helperText:
                                        'Required for encrypted camera streams',
                                  ),
                                  validator: (value) {
                                    if (_hasEncryptedDevices &&
                                        (value == null || value.isEmpty)) {
                                      return 'Encryption password is required for encrypted devices';
                                    }
                                    return null;
                                  },
                                  obscureText: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: state is AuthLoading
                            ? null
                            : _submitCredentials,
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          final message = _useAccessToken
                              ? 'Access tokens can be obtained from the EZVIZ API or dashboard. They provide direct authentication without requiring App Key/Secret.'
                              : 'Visit https://open.ezviz.com/ to get your App Key and App Secret credentials';

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                        child: Text(
                          _useAccessToken
                              ? 'Need help with Access Tokens?'
                              : 'Need credentials? Visit EZVIZ Open Platform',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
