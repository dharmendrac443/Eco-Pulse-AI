import 'package:eco_pulse_ai/login_Page/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';


/// A splash screen that displays the app's logo and navigates to the login page.
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Navigates to the next screen after a delay.
  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _navigateToLoginPage();
    } else {
      _navigateToHomePage(); // Uncomment this line when the HomePage is implemented
    }
  }

  /// Navigates to the login page.
  void _navigateToLoginPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  /// Navigates to the home page.
  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildSplashScreen(),
    );
  }

  /// Builds the splash screen.
  Widget _buildSplashScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLogo(),
          const SizedBox(height: 20),
          _buildAppName(),
          const SizedBox(height: 50),
          _buildLoadingIndicator(),
        ],
      ),
    );
  }

  /// Builds the app logo.
  Widget _buildLogo() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.white,
      child: Icon(Icons.eco, size: 60, color: Colors.green),
    );
  }

  /// Builds the app name.
  Widget _buildAppName() {
    return Text(
      'Clean Green Future',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// Builds the loading indicator.
  Widget _buildLoadingIndicator() {
    return const SpinKitThreeBounce(
      color: Colors.white,
      size: 30.0,
    );
  }
}