import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hand_made/provider/user_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<UserProvider>(context, listen: false).fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("پروفایل من"), centerTitle: true),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userProvider.user == null) {
            return const Center(child: Text("خطا در دریافت اطلاعات کاربر"));
          }
          final user = userProvider.user!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text("${user.firstName} ${user.lastName}"),
                    subtitle: const Text('نام و نام خانوادگی'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(user.email),
                    subtitle: const Text('ایمیل'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(user.phoneNumber),
                    subtitle: const Text('شماره تماس'),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("ویرایش اطلاعات"),
                  onPressed: () {
                    // TODO: navigate to edit page
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
