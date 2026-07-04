import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // 👈 Needed for the graph
import 'database_service.dart';
import 'package:share_plus/share_plus.dart'; // 👈 Add this!

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});

  @override
  _ProgressViewState createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  bool _isLoading = true;
  List<FlSpot> _chartData = [];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  void _loadChartData() async {
    final history = await DatabaseService().getWorkoutHistory();

    if (mounted) {
      setState(() {
        if (history.isNotEmpty) {
          List<FlSpot> spots = [];

          // Loop through the database records and turn them into graph points
          for (int i = 0; i < history.length; i++) {
            double score = (history[i]['formScore'] ?? 0).toDouble();
            spots.add(FlSpot(i.toDouble(), score));
          }

          _chartData = spots;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService().getUserWorkouts(),
      builder: (context, snapshot) {
        int totalWorkouts = 0;
        int avgFormScore = 0;
        int currentStreak = 0;
        int totalReps = 0;

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
            currentStreak = 1;
          }
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷️ HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Progress",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Track your fitness journey",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey[600],
                          ),
                        ),
                      ],
                    ),
                    // 📤 THE SHARE BUTTON
                    IconButton(
                      onPressed: () {
                        // Format the report for WhatsApp/sharing!
                        String report =
                            "📊 *Rehab Ai Progress Report*\n\n"
                            "🔥 Current Streak: $currentStreak days\n"
                            "🏋️ Total Workouts: $totalWorkouts\n"
                            "📈 Avg Form Score: $avgFormScore%\n"
                            "💪 Total Reps: $totalReps\n\n"
                            "Getting stronger and moving better every day! Sent from the Rehab Ai App.";

                        // This opens the native share sheet
                        Share.share(report);
                      },
                      icon: const Icon(
                        Icons.ios_share,
                        color: Color(0xFF4353FF),
                        size: 28,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF4353FF,
                        ).withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // 📊 STATS GRID
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.show_chart,
                        value: "$totalWorkouts",
                        label: "Total Workouts",
                        trendText: "Lifetime",
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        icon: Icons.trending_up,
                        value: "$avgFormScore%",
                        label: "Avg. Form Score",
                        trendText: "Lifetime",
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.military_tech_outlined,
                        value: "$currentStreak days",
                        label: "Current Streak",
                        trendText: "Keep it up!",
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        icon: Icons.multiline_chart,
                        value: "$totalReps",
                        label: "Total Reps",
                        trendText: "Lifetime",
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),

                // 📈 THE DYNAMIC CHART
                Text(
                  "Form Score History",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 16),

                Container(
                  height: 250, // Fixed height for the chart
                  padding: EdgeInsets.only(right: 16, top: 24, bottom: 10),
                  decoration: BoxDecoration(
                    color: Color(
                      0xFF1E293B,
                    ), // Dark background for the chart to pop
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4353FF),
                          ),
                        )
                      : _chartData.isEmpty
                      ? Center(
                          child: Text(
                            "Complete a workout to see your chart!",
                            style: TextStyle(color: Colors.blueGrey[400]),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      "${value.toInt()}",
                                      style: TextStyle(
                                        color: Colors.blueGrey[400],
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: _chartData.isEmpty
                                ? 1
                                : (_chartData.length - 1).toDouble(),
                            minY: 0,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: _chartData,
                                isCurved: true,
                                color: Color(0xFF10B981), // Neon Green
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.2), // Glowing gradient
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                SizedBox(height: 32),

                // 🏆 ACHIEVEMENTS
                Text(
                  "Achievements",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 16),

                AchievementCard(
                  title: "Perfect Form Master",
                  subtitle: "100% form score on 5 workouts",
                  isAchieved: true,
                ),
                AchievementCard(
                  title: "Consistency King",
                  subtitle: "15 day workout streak",
                  isAchieved: false,
                ),
                AchievementCard(
                  title: "Century Club",
                  subtitle: "Complete 100 total workouts",
                  isAchieved: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 🧩 REUSABLE STAT CARD WIDGET
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String trendText;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.trendText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Light blue header area for icon
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Color(0xFFE5EDFF), // Very light blue
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF4353FF), size: 20),
            ),
          ),
          // Data area
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
                ),
                SizedBox(height: 16),
                Text(
                  trendText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF10B981), // Emerald green
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🧩 REUSABLE ACHIEVEMENT CARD WIDGET
class AchievementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isAchieved;

  const AchievementCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isAchieved,
  });

  @override
  Widget build(BuildContext context) {
    Color iconBgColor = isAchieved ? Color(0xFFFFF7E6) : Colors.grey.shade100;
    Color iconColor = isAchieved ? Color(0xFFF5A623) : Colors.grey.shade400;
    Color textColor = isAchieved ? Color(0xFF111827) : Colors.blueGrey.shade400;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Circular Icon Profile
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.blueGrey[400]),
                ),
              ],
            ),
          ),
          // Checkmark for achieved items
          if (isAchieved) Icon(Icons.check, color: Color(0xFFF5A623), size: 24),
        ],
      ),
    );
  }
}
