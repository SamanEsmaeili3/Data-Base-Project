import 'package:flutter/material.dart';
import 'package:hand_made/provider/auth_provider.dart';
import 'package:hand_made/views/widget_tree.dart';
import 'package:provider/provider.dart';

class OtpLoginPage extends StatefulWidget {
  const OtpLoginPage({super.key, required this.emailOrPhoneNumber});

  final String emailOrPhoneNumber;

  @override
  State<OtpLoginPage> createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends State<OtpLoginPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ورود دو مرحله ای',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'کد تایید',
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: () {
                  setState(() {});
                },
              ),
              SizedBox(height: 10),
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
                            content: Text('لطفا کد تایید را وارد کنید'),
                          ),
                        );
                        return;
                      }
                      final isSuccess = await authProvider.loginWithOtp(
                        widget.emailOrPhoneNumber,
                        _controller.text,
                      );
                      if (isSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ورود با موفقیت انجام شد.'),
                          ),
                        );
                        // Navigate to the main app page
                        // TODO: Remove back botton functionality
                        // to prevent going back to the login page
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const widgetTree(),
                          ),
                          (route) => false,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(authProvider.errorMessage ?? ''),
                          ),
                        );
                      }
                    },
                    child: const Text('ورود'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
