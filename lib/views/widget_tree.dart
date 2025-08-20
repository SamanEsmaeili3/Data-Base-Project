import 'package:flutter/material.dart';
import 'package:hand_made/provider/auth_provider.dart';
import 'package:hand_made/views/pages/booking_history_page.dart';
import 'package:hand_made/views/pages/welcome_page.dart';
import 'package:provider/provider.dart';
import '../data/notifiers.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/search_page.dart';
import 'widgets/navbar_widget.dart';

// This global list is fine.
List<Widget> pages = [
  const ProfilePage(),
  const SearchPage(),
  const BookingHistoryPage(),
];

class widgetTree extends StatelessWidget {
  const widgetTree({super.key});

  // Add a list of titles corresponding to the pages list
  final List<String> _titles = const ['پروفایل', 'جستجوی بلیط', 'تاریخچه رزرو'];

  @override
  Widget build(BuildContext context) {
    // This ValueListenableBuilder controls the page content and AppBar title
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, pageIndex, child) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(_titles[pageIndex]),
            centerTitle: true,
            actions: [
              // Dark mode toggle button
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
              // Show logout button only on the profile page (index 0)
              if (pageIndex == 0)
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'خروج',
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomePage()),
                      (route) => false,
                    );
                  },
                ),
            ],
          ),
          body: pages[pageIndex],
          bottomNavigationBar: const NavbarWidget(),
        );
      },
    );
  }
}
