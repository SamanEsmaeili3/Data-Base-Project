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

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder will now control the AppBar title and body
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, pageIndex, child) {
        return Scaffold(body: Row(children: []));
      },
    );
  }
}
