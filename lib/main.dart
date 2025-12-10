import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'fingerprint_auth_page.dart';
import 'signup_page.dart';
import 'login_page.dart';
import 'portfolio_page.dart'; // Import portfolio page!

final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

void main() {
  runApp(const DharPayApp());
}
class DharPayApp extends StatelessWidget {
  const DharPayApp({super.key});

  // This logic is now used only to check whether to show Signup before fingerprint or not
  Future<bool> _hasAccount() async {
    // Use username for consistency!
    final username = await secureStorage.read(key: 'user_username');
    return username != null && username.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DharPay',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FF),
        fontFamily: 'Poppins',
      ),
      home: FutureBuilder<bool>(
        future: _hasAccount(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
          }
          if (snapshot.data == false) {
            // No account found, go to signup FIRST
            return const SignupPage();
          }
          // Show fingerprint, on success go PortfolioPage directly
          return FingerprintAuthPage(
            onAuthenticated: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PortfolioPage()),
              );
            },
          );
        },
      ),
      routes: {
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/portfolio': (context) => const PortfolioPage(),
      },
    );
  }
}
