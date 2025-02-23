import 'package:eco_pulse_ai/login_Page/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent! Check your inbox.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitleText(),
                SizedBox(height: 30),
                _buildInstructionText(),
                SizedBox(height: 20),
                _buildEmailTextField(),
                SizedBox(height: 30),
                _buildResetPasswordButton(),
                SizedBox(height: 20),
                _buildBackToLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleText() {
    return Text(
      'Forgot Password',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade700,
      ),
    );
  }

  Widget _buildInstructionText() {
    return Text(
      'Enter your email to receive a password reset link.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
    );
  }

  Widget _buildEmailTextField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email, color: Colors.green.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value!.isEmpty ? 'Enter your email' : null,
    );
  }

  Widget _buildResetPasswordButton() {
    return ElevatedButton(
      onPressed: _resetPassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(vertical: 15),
      ),
      child: Text(
        'Reset Password',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return TextButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      },
      child: Text(
        'Back to Login',
        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
      ),
    );
  }
}
