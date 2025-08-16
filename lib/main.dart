import 'package:flutter/material.dart';
import 'package:hand_made/data/notifiers.dart';
import 'package:hand_made/views/pages/welcome_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkModeNotifier,
      builder: (context, value, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: value ? ThemeData.dark() : ThemeData.light(),
          title: 'سفرچی',
          home: WelcomePage(),
        );
      },
    );
  }
}
