import 'package:flutter/material.dart';
import 'package:hand_made/provider/auth_provider.dart';
import 'package:hand_made/provider/user_provider.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userProvider.user == null) {
            return const Center(child: Text("خطا در بارگذاری اطلاعات."));
          }
          final user = userProvider.user!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text("${user.firstName} ${user.lastName}"),
                  subtitle: const Text('نام و نام خانوادگی'),
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(user.email),
                  subtitle: const Text('ایمیل'),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(user.phoneNumber),
                  subtitle: const Text('شماره همراه'),
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: Text(user.role),
                  subtitle: const Text('نقش کاربری'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
