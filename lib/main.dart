import 'package:flutter/material.dart';
import 'plan.dart';
import 'progress.dart';
import 'help.dart';
// 👈 Updated this line to point to your new file!
import 'workout_selection.dart';
import 'welcome.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_service.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(), // Start at the wrapper screen
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
    HomeView(),
    PlanScreen(),
    ProgressView(),
    HelpView(), // Placeholder
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              "Rehab Ai",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.person_outline, color: Colors.black, size: 28),
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
                    Icon(Icons.person, color: Colors.blueGrey[700], size: 20),
                    SizedBox(width: 12),
                    Text('My Profile'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              // Working Logout Button
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text(
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
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex, // Highlights active tab
        onTap: _onItemTapped, // Switches tabs
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[600],
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

// 🏠 HOME VIEW (Your previous MainMenu code)
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: DatabaseService().getUserProfile(),
      builder: (context, profileSnapshot) {
        String userName = "Welcome Back!";
        if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
          final data = profileSnapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('name')) {
            userName = "Welcome ${data['name']}!";
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: DatabaseService().getUserWorkouts(),
          builder: (context, workoutsSnapshot) {
            int totalWorkouts = 0;
            int totalReps = 0;
            int avgFormScore = 0;

            if (workoutsSnapshot.hasData) {
              final workouts = workoutsSnapshot.data!.docs;

              totalWorkouts = workouts.length;

              if (workouts.isNotEmpty) {
                int totalScore = 0;
                for (var doc in workouts) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalReps += (data['reps'] as num?)?.toInt() ?? 0;
                  totalScore += (data['formScore'] as num?)?.toInt() ?? 0;
                }
                avgFormScore = (totalScore / workouts.length).round();
              }
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Ready to improve your form?",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const WorkoutSelectionScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.play_arrow_outlined,
                          color: Colors.white,
                        ),
                        label: Text(
                          "Start New Workout",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B0F19),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 32),
                    Text(
                      "Your Summary",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 16),
                    SummaryCard(
                      icon: Icons.calendar_today_outlined,
                      title: "Total Workouts",
                      value: "$totalWorkouts",
                    ),
                    SummaryCard(
                      icon: Icons.adjust,
                      title: "Total Reps",
                      value: "$totalReps",
                    ),
                    SummaryCard(
                      icon: Icons.trending_up,
                      title: "Avg. Form Score",
                      value: "$avgFormScore%",
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 24),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.blueGrey[600]),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
