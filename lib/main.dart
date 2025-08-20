import 'package:flutter/material.dart';
import 'package:hand_made/data/notifiers.dart';
import 'package:hand_made/provider/auth_provider.dart';
import 'package:hand_made/provider/booking_provider.dart';
import 'package:hand_made/provider/ticket_provider.dart';
import 'package:hand_made/provider/user_provider.dart';
import 'package:hand_made/views/pages/welcome_page.dart';
import 'package:provider/provider.dart';

void main() {
  // 1. Wrap your app in MultiProvider to provide the state down the widget tree.
  runApp(
    MultiProvider(
      providers: [
        // Independent providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),

        // Dependent providers that need the auth token
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (context, auth, previousUserProvider) {
            // Update the UserProvider with the latest token from AuthProvider
            previousUserProvider?.updateAuthToken(auth.token ?? '');
            return previousUserProvider!;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (_) => BookingProvider(),
          update: (context, auth, previousBookingProvider) {
            // Update the BookingProvider with the latest token from AuthProvider
            previousBookingProvider?.updateAuthToken(auth.token ?? '');
            return previousBookingProvider!;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
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
