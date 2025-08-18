import 'package:flutter/material.dart';
import 'package:hand_made/provider/auth_provider.dart';
import 'package:hand_made/views/pages/otp_login_page.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'ایمیل یا شماره همراه',
              ),
              onEditingComplete: () {},
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.authStatus == AuthStatus.authenticating) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    if (_controller.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'لطفا ایمیل یا شماره همراه را وارد کنید',
                          ),
                        ),
                      );
                      return;
                    }
                    final success = await authProvider.sendOtp(
                      _controller.text,
                    );
                    if (success && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => OtpLoginPage(
                                emailOrPhoneNumber: _controller.text,
                              ),
                        ),
                      );
                    }
                  },
                  child: const Text('دریافت کد تایید'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
