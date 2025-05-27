import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_flutter_app/screens/fuel_delivery_page.dart';
import 'package:my_flutter_app/screens/road_service_page.dart'; // Import RoadServicePage
import 'package:my_flutter_app/screens/book_service_page.dart'; // Import BookServicePage
import 'package:my_flutter_app/screens/chatbot_page.dart'; // Import ChatbotPage
import 'package:my_flutter_app/screens/status_page.dart'; // Import StatusPage
import 'package:my_flutter_app/screens/login_page.dart'; // Import LoginPage
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
  
  // TODO: Load Supabase configuration from environment variables or secure storage
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Supabase configuration is missing. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.');
  }
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Simple App',
      home: const LoginPage(), // Start with LoginPage
      routes: {'/login': (context) => const LoginPage()},
    );
  }
}

class MainNavigation extends StatefulWidget {
  final String username; // Add username as a parameter

  const MainNavigation({super.key, required this.username});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      FuelDeliveryPage(username: widget.username),
      RoadServicePage(username: widget.username),
      BookServicePage(username: widget.username),
      const ChatbotPage(),
      StatusPage(username: widget.username),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.black, // Set selected icon color to black
        unselectedItemColor: Colors.grey, // Set unselected icon color to gray
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'Fuel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.car_repair),
            label: 'Road Service',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Book Service',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chatbot'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Status'),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('This is the $title page.')),
    );
  }
}
