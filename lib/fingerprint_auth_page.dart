import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class FingerprintAuthPage extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const FingerprintAuthPage({Key? key, required this.onAuthenticated}) : super(key: key);

  @override
  State<FingerprintAuthPage> createState() => _FingerprintAuthPageState();
}

class _FingerprintAuthPageState extends State<FingerprintAuthPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authStatus = 'Scan your fingerprint to proceed';

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      bool supported = await auth.isDeviceSupported();
      bool canCheck = await auth.canCheckBiometrics;

      if (!supported) {
        setState(() => _authStatus = "Your device does not support biometrics");
        return;
      }

      if (!canCheck) {
        setState(() => _authStatus = "No biometric sensors available");
        return;
      }

      setState(() {
        _isAuthenticating = true;
        _authStatus = "Authenticating...";
      });

      bool authenticated = await auth.authenticate(
        localizedReason: "Please authenticate to continue",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,      // ⭐ REQUIRED BY ANDROID 15
        ),
      );

      setState(() => _isAuthenticating = false);

      if (authenticated) {
        setState(() => _authStatus = "Authentication successful!");
        await Future.delayed(const Duration(milliseconds: 300));
        widget.onAuthenticated();
      } else {
        setState(() => _authStatus = "Authentication failed. Tap retry.");
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authStatus = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fingerprint, size: 100, color: Color(0xFF667eea)),
                    const SizedBox(height: 20),
                    Text(
                      _authStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 30),
                    if (!_isAuthenticating)
                      ElevatedButton(
                        onPressed: _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                        child: const Text("Retry", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
