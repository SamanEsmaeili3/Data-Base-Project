// lib/views/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:hand_made/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../data/notifiers.dart'; // Your notifier
import '../widgets/navbar_widget.dart'; // Your navbar
import 'profile_page.dart';
import 'search_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // The pages are the content widgets WITHOUT Scaffolds
  final List<Widget> _pages = const [
    ProfilePage(),
    SearchPage(),
    Center(
      child: Text("Home Content"),
    ), // Placeholder for the actual home page content
  ];

  // Titles for the AppBar corresponding to each page
  final List<String> _titles = const ['Profile', 'Search Tickets', 'Home'];

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder will now control the AppBar title and body
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, pageIndex, child) {
        return Scaffold(
          // The AppBar is now controlled by HomePage
          appBar: AppBar(
            title: Center(child: Text('سفرچی')),
            actions: [
              IconButton(
                onPressed: () {
                  isDarkModeNotifier.value = !isDarkModeNotifier.value;
                },
                icon: ValueListenableBuilder(
                  valueListenable: isDarkModeNotifier,
                  builder: (context, isDarkMode, child) {
                    return Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    );
                  },
                ),
              ),
            ],
          ),
          // The body changes based on the selected page
          body: _pages[pageIndex],
          // The bottom navigation bar remains the same
          // bottomNavigationBar: const NavbarWidget(),
        );
      },
    );
  }
}
