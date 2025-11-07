// lib/success_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'main.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  Future<void> _logoutAndResetPin(BuildContext context) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.delete(key: 'user_pin');

    // Return to AuthScreen (replace)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // your assets/success.json must exist and be registered in pubspec.yaml
                Lottie.asset('assets/success.json', width: 220, repeat: false),
                const SizedBox(height: 20),
                const Text(
                  'Success!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _logoutAndResetPin(context),
                  child: const Text('Logout / Reset PIN', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
