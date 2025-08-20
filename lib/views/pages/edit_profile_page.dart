import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hand_made/models/user_model.dart';
import 'package:hand_made/provider/user_provider.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Create controllers for each form field
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    // Pre-fill the controllers with the user's current data
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ویرایش پروفایل')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'نام'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'نام خانوادگی'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'شماره تماس'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'ایمیل'),
            ),
            const SizedBox(height: 32),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return userProvider.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('ذخیره تغییرات'),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    // Create the update model with the new data from the controllers
    final profileData = UserProfileUpdateModel(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text,
    );

    // Call the provider to update the user profile
    final success = await Provider.of<UserProvider>(
      context,
      listen: false,
    ).updateUserProfile(profileData);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پروفایل با موفقیت به‌روزرسانی شد.'),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to the profile page after a successful update
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در به‌روزرسانی پروفایل.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
