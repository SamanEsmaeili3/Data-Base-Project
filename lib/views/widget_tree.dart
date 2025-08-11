import 'package:flutter/material.dart';
import 'package:hand_made/data/notifiers.dart';
import 'package:hand_made/views/pages/home_page.dart';
import 'package:hand_made/views/pages/login_page.dart';
import 'package:hand_made/views/pages/profile_page.dart';
import 'package:hand_made/views/pages/search_page.dart';
import 'package:hand_made/views/pages/signup_page.dart';
import 'package:hand_made/views/widgets/navbar_widget.dart';

List<Widget> pages = [const LoginPage(), const SearchPage(), const HomePage()];

class widgetTree extends StatelessWidget {
  const widgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hand Made'),
        actions: [
          IconButton(
            onPressed: () {
              isDarkModeNotifier.value = !isDarkModeNotifier.value;
            },
            icon: ValueListenableBuilder(
              valueListenable: isDarkModeNotifier,
              builder: (context, isDarkMode, child) {
                return Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode);
              },
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, value, child) {
          return pages.elementAt(value);
        },
      ),
      bottomNavigationBar: NavbarWidget(),
    );
  }
}
