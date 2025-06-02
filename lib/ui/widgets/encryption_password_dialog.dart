import 'package:flutter/material.dart';

class EncryptionPasswordDialog extends StatefulWidget {
  final String cameraName;
  final String deviceSerial;

  const EncryptionPasswordDialog({
    super.key,
    required this.cameraName,
    required this.deviceSerial,
  });

  @override
  State<EncryptionPasswordDialog> createState() =>
      _EncryptionPasswordDialogState();
}

class _EncryptionPasswordDialogState extends State<EncryptionPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.enhanced_encryption,
            color: Colors.amber[700],
            size: 24,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Encrypted Camera',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Camera "${widget.cameraName}" requires a verification code to access the video stream.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Device: ${widget.deviceSerial}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Verification Code',
              hintText: 'Enter camera verification code',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: const OutlineInputBorder(),
              errorMaxLines: 2,
            ),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitPassword(),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _rememberPassword,
            onChanged: (bool? value) {
              setState(() {
                _rememberPassword = value ?? false;
              });
            },
            title: const Text(
              'Remember password for this camera',
              style: TextStyle(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 8),
          Text(
            'Note: This verification code is usually found on the camera label or in the camera settings.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _passwordController.text.isEmpty ? null : _submitPassword,
          child: const Text('Connect'),
        ),
      ],
    );
  }

  void _submitPassword() {
    final password = _passwordController.text.trim();
    if (password.isNotEmpty) {
      Navigator.of(context).pop({
        'password': password,
        'remember': _rememberPassword,
      });
    }
  }
}

/// Utility function to show the encryption password dialog
Future<Map<String, dynamic>?> showEncryptionPasswordDialog(
  BuildContext context, {
  required String cameraName,
  required String deviceSerial,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return EncryptionPasswordDialog(
        cameraName: cameraName,
        deviceSerial: deviceSerial,
      );
    },
  );
}