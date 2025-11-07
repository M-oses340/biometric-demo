// lib/main.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'success_screen.dart'; // make sure this file exists
import 'package:lottie/lottie.dart';

void main() {
  runApp(const BiometricApp());
}

class BiometricApp extends StatelessWidget {
  const BiometricApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biometrics Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final TextEditingController _pinController = TextEditingController();

  bool _biometricAvailable = false;
  bool _isFace = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsAndPin();
    // attempt biometric shortly after screen shows
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_biometricAvailable) _authenticateBiometric();
    });
  }

  Future<void> _checkBiometricsAndPin() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      // if isDeviceSupported is available in your version, you can also call it;
      // catching errors if it's not present is safe.
      bool supported = true;
      try {
        supported = await _auth.isDeviceSupported();
      } catch (_) {
        // older versions may not expose isDeviceSupported — ignore
      }

      final types = await _auth.getAvailableBiometrics();
      setState(() {
        _biometricAvailable = (canCheck && supported);
        _isFace = types.contains(BiometricType.face);
      });
    } catch (e) {
      debugPrint('check biometrics error: $e');
      setState(() {
        _biometricAvailable = false;
        _isFace = false;
      });
    }
  }

  Future<void> _authenticateBiometric() async {
    if (!_biometricAvailable) return;

    setState(() => _isLoading = true);

    try {
      // Minimal compatible call — older local_auth versions accept biometricOnly
      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to continue',
        biometricOnly: true,
      );

      if (authenticated) {
        _goToSuccess();
      }
    } catch (e) {
      debugPrint('biometric auth error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onPinCompleted(String enteredPin) async {
    // If there is no stored PIN, save the entered one (first-time)
    final stored = await _secureStorage.read(key: 'user_pin');
    if (stored == null) {
      await _secureStorage.write(key: 'user_pin', value: enteredPin);
      _goToSuccess();
    } else if (stored == enteredPin) {
      _goToSuccess();
    } else {
      // wrong PIN
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong PIN')),
        );
        _pinController.clear();
      }
    }
  }

  void _goToSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessScreen()),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputHint = 'Enter your 4-digit PIN';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              children: [
                const SizedBox(height: 28),
                const Text(
                  'Welcome',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(inputHint, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 28),
                Pinput(
                  controller: _pinController,
                  length: 4,
                  obscureText: true,
                  onCompleted: _onPinCompleted,
                ),
                const Spacer(),
                if (_biometricAvailable) ...[
                  const Text('or', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _authenticateBiometric,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : Icon(_isFace ? Icons.tag_faces : Icons.fingerprint,
                            size: 36, color: Colors.blue.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_isFace ? 'Use Face Unlock' : 'Use Fingerprint',
                      style: TextStyle(fontSize: 16, color: Colors.blue.shade700)),
                  const SizedBox(height: 28),
                ] else ...[
                  const SizedBox(height: 60),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
