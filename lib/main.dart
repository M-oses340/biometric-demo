import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pinput/pinput.dart';

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
  final TextEditingController controller = TextEditingController();
  final String pin = "1234";

  bool biometricAvailable = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkBiometric();
  }

  Future<void> checkBiometric() async {
    try {
      final can = await auth.canCheckBiometrics;
      final supported = await auth.isDeviceSupported();
      setState(() => biometricAvailable = can && supported);
    } catch (e) {
      print(e);
    }
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
                onCompleted: (value) {
                  if (value == pin) navigate();
                  controller.clear();
                },
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
                              : Icon(Icons.fingerprint, size: 30, color: Colors.blue.shade600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text("Use Fingerprint", style: TextStyle(fontSize: 18, color: Colors.blue.shade600)),
                    const SizedBox(height: 20),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> authenticateBiometric() async {
    setState(() => isLoading = true);

    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to continue',
        biometricOnly: true,
      );

      if (authenticated) navigate();
    } catch (e) {
      print(e);
    } finally {
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
