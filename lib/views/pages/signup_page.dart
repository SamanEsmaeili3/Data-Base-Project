import 'package:flutter/material.dart';
import 'package:hand_made/provider/auth_provider.dart';
import 'package:hand_made/views/widget_tree.dart';
import 'package:provider/provider.dart';
import 'package:hand_made/models/user_model.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ثبت نام در سفرچی")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          // To prevent overflow
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'نام'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'نام خانوادگی'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'ایمیل'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'شماره همراه'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'رمز عبور'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'شهر'),
              ),
              const SizedBox(height: 30),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.authStatus == AuthStatus.authenticating) {
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      final userToCreate = UserCreateModel(
                        firstName: _firstNameController.text,
                        lastName: _lastNameController.text,
                        email: _emailController.text,
                        phoneNumber: _phoneController.text,
                        password: _passwordController.text,
                        city: _cityController.text,
                      );
                      // You need to add the signUp method to your AuthProvider
                      authProvider
                          .signUp(userToCreate)
                          .then((success) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ثبت نام با موفقیت انجام شد.'),
                                ),
                              );
                              // TODO: Remove back button functionality
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const widgetTree(),
                                ),
                              ); // Go back to the previous page
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    authProvider.errorMessage ??
                                        'خطا در ثبت نام',
                                  ),
                                ),
                              );
                            }
                          })
                          .catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطا: $error')),
                            );
                          });
                    },
                    child: const Text("ثبت نام"),
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
