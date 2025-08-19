import 'package:flutter/material.dart';
import 'package:hand_made/data/notifiers.dart';

class NavbarWidget extends StatelessWidget {
  const NavbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, value, child) {
        return NavigationBar(
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.person_4_rounded),
              label: "",
            ),
            NavigationDestination(icon: Icon(Icons.search), label: ""),
            NavigationDestination(icon: Icon(Icons.home), label: ""),
          ],
          onDestinationSelected: (int value) {
            selectedPageNotifier.value = value;
          },
        );
      },
    );
  }
}
