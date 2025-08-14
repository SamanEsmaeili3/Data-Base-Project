import 'package:flutter/material.dart';
import 'package:hand_made/views/pages/otp_login_page.dart';
import 'package:hand_made/views/widget_tree.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ورود به سفرچی"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'ایمیل یا شماره همراه',
              ),
              onEditingComplete: () {
                setState(() {});
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(
                  double.infinity,
                  50,
                ), // Full width button
              ),
              onPressed: () {
                // Pass the TextField value to OtpLoginPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            OtpLoginPage(emailOrPhoneNumber: controller.text),
                  ),
                );
              },
              child: const Text('ورود'),
            ),
          ],
        ),
      ),
    );
  }
}
