import 'package:flutter/material.dart';
import 'package:hand_made/views/pages/otp_login_page.dart';
import 'package:hand_made/views/pages/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'شماره همراه یا ایمیل',
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: () {
                  setState(() {});
                },
              ),
              Text(controller.text),
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
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50), // Full width button
            ),
            onPressed: () {
              // Handle login action
              // TODO: Implement login functionality
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OtpLoginPage()),
              );
            },
            child: const Text('ورود'),
          ),
        ],
      ),
    );
  }
}
