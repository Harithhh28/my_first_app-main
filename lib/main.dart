import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'plan.dart';
import 'progress.dart';
import 'help.dart';
import 'home.dart';
import 'welcome.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_service.dart';
import 'login.dart';
import 'package:camera/camera.dart';
import 'edit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';


// 👇 Add this global variable so any screen can access the cameras
late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 👇 Ask the phone for its cameras before the app boots up
  cameras = await availableCameras();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rehab Ai',
      theme: AppTheme.dark,
      home: const AuthWrapper(),
    );
  }
}

// 🔐 AUTH WRAPPER TO HANDLE RELOGIN
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the connection is busy, show a loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If a user is logged in, send them directly to the main app!
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }

        // Otherwise, send them to the Welcome screen
        return const WelcomeScreen();
      },
    );
  }
}

// 🧭 WRAPPER SCREEN FOR NAVIGATION
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of pages to show based on selected tab
  final List<Widget> _pages = [
    const HomeScreen(),
    PlanScreen(),
    ProgressScreen(),
    HelpView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFF1E293B), height: 1.0),
        ),
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: const Color(0xFF4353FF)),
            const SizedBox(width: 8),
            const Text(
              "Rehab Ai",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
          icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
            offset: const Offset(0, 50), // Pushes the menu slightly down
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              } else if (value == 'logout') {
                // 1. Log them out using our service
                await AuthService().signOut();

                // 2. Send them back to the Login Screen & clear the history
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // Placeholder for future profile page
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.blueGrey[300], size: 20),
                    const SizedBox(width: 12),
                    const Text('My Profile', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuDivider(),
              // Working Logout Button
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _pages[_selectedIndex], // Shows the active page
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF111827),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF4353FF),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.home),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.calendar_month),
            ),
            label: 'Rehab Plan',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            activeIcon: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.show_chart), // The filled version
            ),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            activeIcon: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.help), // The filled version
            ),
            label: 'Help',
          ),
        ],
      ),
    ); // <-- Restored missing bracket for Scaffold
  } // <-- Restored missing bracket for build method
} // <-- Restored missing bracket for _MainScreenState

