import 'package:flutter/material.dart';
import 'package:hand_made/views/pages/login_page.dart';
import 'package:hand_made/views/pages/signup_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SafeArea(
              child: Column(
                children: [
                  const Text(
                    'به سفرچی خوش آمدید',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Move TextButton right above ElevatedButton
            Column(
              children: [
                TextButton(
                  onPressed: () {
                    // Navigate to signup page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupPage()),
                    );
                  },
                  child: const Text('ثبت نام'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50), // Full width button
                  ),
                  onPressed: () {
                    // Handle login action
                    // TODO: Implement login functionality
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: const Text('ورود'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
