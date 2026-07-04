import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';
import 'edit_profile.dart';
import 'auth_service.dart';
import 'login.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // We use StreamBuilder so the profile stats update instantly when they finish a workout!
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService().getUserWorkouts(),
      builder: (context, snapshot) {
        int totalWorkouts = 0;
        int avgFormScore = 0;
        int totalReps = 0;
        int currentStreak = 0;

        if (snapshot.hasData) {
          final workouts = snapshot.data!.docs;
          totalWorkouts = workouts.length;

          if (workouts.isNotEmpty) {
            int totalScore = 0;
            for (var doc in workouts) {
              final data = doc.data() as Map<String, dynamic>;
              totalReps += (data['reps'] as num?)?.toInt() ?? 0;
              totalScore += (data['formScore'] as num?)?.toInt() ?? 0;
            }
            avgFormScore = (totalScore / workouts.length).round();
            currentStreak = 1; // Simplified streak
          }
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 👤 USER AVATAR & HEADER
                SizedBox(height: 20),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE5EDFF),
                        border: Border.all(color: Color(0xFF4353FF), width: 3),
                        image: DecorationImage(
                          image: NetworkImage(
                            "https://api.dicebear.com/7.x/avataaars/png?seed=RehabAthlete",
                          ), // Fun placeholder avatar
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981), // Green status dot
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  "Alex Athlete",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  "Pro Member • Joined June 2026",
                  style: TextStyle(fontSize: 14, color: Colors.blueGrey[400]),
                ),
                SizedBox(height: 32),

                // 📊 THE LIFETIME SUMMARY CARD
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4353FF).withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Lifetime Summary",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.military_tech, color: Color(0xFFF5A623)),
                        ],
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfileStat("Workouts", "$totalWorkouts"),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.blueGrey[700],
                          ),
                          _buildProfileStat("Avg Form", "$avgFormScore%"),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.blueGrey[700],
                          ),
                          _buildProfileStat("Total Reps", "$totalReps"),
                        ],
                      ),
                      SizedBox(height: 24),

                      // 📤 WHATSAPP / SHARE REPORT BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // 📝 The text that gets sent to WhatsApp
                            String report =
                                "📊 *Rehab Ai Progress Report*\n\n"
                                "🔥 Current Streak: $currentStreak days\n"
                                "🏋️ Total Workouts: $totalWorkouts\n"
                                "📈 Avg Form Score: $avgFormScore%\n"
                                "💪 Total Reps: $totalReps\n\n"
                                "Getting stronger and moving better every day! Sent from the Rehab Ai App.";
                            Share.share(report);
                          },
                          icon: Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            "Share Report",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4353FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // ⚙️ MENU OPTIONS
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildMenuRow(
                  Icons.person_outline,
                  "Edit Profile",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                  },
                ),
                _buildMenuRow(Icons.notifications_outlined, "Notifications"),
                _buildMenuRow(
                  Icons.health_and_safety_outlined,
                  "Connected Devices",
                ),
                _buildMenuRow(
                  Icons.logout,
                  "Log Out",
                  isDestructive: true,
                  onTap: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🧩 HELPER: Quick Stat Column for the Summary Card
  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
        ),
      ],
    );
  }

  // 🧩 HELPER: Settings Menu Rows (Now clickable!)
  Widget _buildMenuRow(
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    Color itemColor = isDestructive ? Colors.redAccent : Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap, // 👈 Now it executes whatever we pass to it!
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withValues(alpha: 0.1)
                      : Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: itemColor, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: itemColor,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.blueGrey[300]),
            ],
          ),
        ),
      ),
    );
  }
}
