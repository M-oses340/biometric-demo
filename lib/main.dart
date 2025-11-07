import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const BiometricApp());
}

class BiometricApp extends StatelessWidget {
  const BiometricApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final TextEditingController controller = TextEditingController();

  bool biometricAvailable = false;
  bool isLoading = false;
  bool isFace = false;

  @override
  void initState() {
    super.initState();
    checkBiometric();
    autoTryBiometric();
  }

  Future<void> checkBiometric() async {
    try {
      bool can = await auth.canCheckBiometrics;
      bool supported = await auth.isDeviceSupported();
      List<BiometricType> types = await auth.getAvailableBiometrics();

      setState(() {
        biometricAvailable = can && supported;
        isFace = types.contains(BiometricType.face);
      });
    } catch (_) {}
  }

  /// Auto-run fingerprint when screen opens
  Future<void> autoTryBiometric() async {
    await Future.delayed(const Duration(milliseconds: 600));
    authenticateBiometric();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text("Enter PIN", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Enter your 4-digit PIN", style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 30),

              Pinput(
                controller: controller,
                length: 4,
                obscureText: true,
                onCompleted: saveAndLogin,
              ),

              const Spacer(),

              if (biometricAvailable)
                Column(
                  children: [
                    const Text("or", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: isLoading ? null : authenticateBiometric,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Center(
                          child: isLoading
                              ? const CircularProgressIndicator(strokeWidth: 2)
                              : Icon(isFace ? Icons.tag_faces : Icons.fingerprint,
                              size: 30, color: Colors.blue.shade600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(isFace ? "Use Face Unlock" : "Use Fingerprint",
                        style: TextStyle(fontSize: 18, color: Colors.blue.shade600)),
                    const SizedBox(height: 20),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Securely Save PIN & Validate
  Future<void> saveAndLogin(String value) async {
    String? savedPin = await secureStorage.read(key: "user_pin");

    if (savedPin == null) {
      await secureStorage.write(key: "user_pin", value: value);
      navigate();
    } else if (savedPin == value) {
      navigate();
    }

    controller.clear();
  }

  Future<void> authenticateBiometric() async {
    setState(() => isLoading = true);

    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Confirm your identity',
        biometricOnly: true,
      );

      if (authenticated) navigate();
    } catch (_) {} finally {
      setState(() => isLoading = false);
    }
  }

  void navigate() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SecondScreen()),
    );
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Text("Success!",
            style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
