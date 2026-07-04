import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';
import 'workout.dart';

class WorkoutSelectionScreen extends StatefulWidget {
  const WorkoutSelectionScreen({super.key});

  @override
  State<WorkoutSelectionScreen> createState() => _WorkoutSelectionScreenState();
}

class _WorkoutSelectionScreenState extends State<WorkoutSelectionScreen> {
  // 🏥 Inside selection state
  String selectedInjury = "Knee"; // Toggle between "Knee" and "Shoulder"

  final Map<String, List<Map<String, dynamic>>> rehabProtocols = {
    "Shoulder": [
      {"name": "Front Arm Raise", "icon": Icons.arrow_upward, "target": "Front Deltoid & Rotator Cuff"},
      {"name": "Lateral Raises", "icon": Icons.unfold_more, "target": "Lateral Deltoid Mobility"},
      {"name": "Arm Twist", "icon": Icons.cached, "target": "Internal/External Rotation"},
      {"name": "Half Bow", "icon": Icons.architecture, "target": "Posterior Chain Stretch"},
      {"name": "Full Bow", "icon": Icons.accessibility, "target": "Thoracic Extension"},
      {"name": "Arm Circles", "icon": Icons.looks, "target": "Scapular Range of Motion"},
    ],
    "Knee": [
      {"name": "Quad Stretch (Left)", "icon": Icons.airline_seat_legroom_extra, "target": "Left Quad Flexibility"},
      {"name": "Quad Stretch (Right)", "icon": Icons.airline_seat_legroom_extra, "target": "Right Quad Flexibility"},
      {"name": "Leg Raises", "icon": Icons.vertical_align_top, "target": "Hip Flexor & Quad Strength"},
      {"name": "Squat", "icon": Icons.shutter_speed, "target": "Knee Stability & Glute Load"},
      {"name": "Split Squat (Left)", "icon": Icons.accessibility_new, "target": "Left Knee VMO Focus"},
      {"name": "Split Squat (Right)", "icon": Icons.accessibility_new, "target": "Right Knee VMO Focus"},
      {"name": "Mountain Climb", "icon": Icons.terrain, "target": "Joint Fluidity & Core Alignment"},
    ]
  };

  // Keep track of which card is currently expanded to view the Coach's Note
  String? _expandedCard;

  @override
  Widget build(BuildContext context) {
    Color trackColor = selectedInjury == "Knee" ? const Color(0xFF4353FF) : const Color(0xFF10B981);
    List<Map<String, dynamic>> activeExercises = rehabProtocols[selectedInjury] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19), // Dark, calming theme
      appBar: AppBar(
        title: const Text(
          "AI Rehab Selection",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getUserPrescriptions(),
        builder: (context, snapshot) {
          Map<String, Map<String, dynamic>> prescriptions = {};
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              prescriptions[doc.id] = Map<String, dynamic>.from(doc.data() as Map);
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  "What are we healing today?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Select your joint track. The AI automatically adjusts reps and intensity based on your performance and pain thresholds.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey[400],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // 🎛️ PREMIUM GRADIENT SEGMENTED CONTROL
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Knee Segment
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedInjury = "Knee";
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: selectedInjury == "Knee"
                                  ? const LinearGradient(
                                      colors: [Color(0xFF4353FF), Color(0xFF1E40AF)],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: selectedInjury == "Knee"
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4353FF).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.airline_seat_legroom_extra,
                                    color: selectedInjury == "Knee" ? Colors.white : Colors.blueGrey[400],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Knee Rehab",
                                    style: TextStyle(
                                      color: selectedInjury == "Knee" ? Colors.white : Colors.blueGrey[400],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Shoulder Segment
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedInjury = "Shoulder";
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: selectedInjury == "Shoulder"
                                  ? const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF047857)],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: selectedInjury == "Shoulder"
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.accessibility_new,
                                    color: selectedInjury == "Shoulder" ? Colors.white : Colors.blueGrey[400],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Shoulder Rehab",
                                    style: TextStyle(
                                      color: selectedInjury == "Shoulder" ? Colors.white : Colors.blueGrey[400],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 📜 PROTOCOL LIST (DYNAMICS VIA FIRESTORE)
                Expanded(
                  child: ListView.builder(
                    itemCount: activeExercises.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final exercise = activeExercises[index];
                      final name = exercise["name"] as String;
                      final icon = exercise["icon"] as IconData;
                      final target = exercise["target"] as String;

                      // Read prescription values
                      final presc = prescriptions[name];
                      final int targetReps = presc != null ? (presc["prescribedReps"] ?? 10) : 10;
                      final String tier = presc != null ? (presc["adaptationTier"] ?? "Baseline") : "Baseline";
                      final String level = presc != null ? (presc["currentLevel"] ?? "Volume Initial") : "Volume Initial";
                      final String? coachNote = presc != null ? presc["coachNote"] : null;

                      Color badgeColor;
                      if (tier.contains("PROGRESSION")) {
                        badgeColor = const Color(0xFF10B981); // Green
                      } else if (tier.contains("REGRESSION")) {
                        badgeColor = Colors.redAccent;
                      } else {
                        badgeColor = const Color(0xFF4353FF); // Blue
                      }

                      bool isExpanded = _expandedCard == name;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isExpanded ? trackColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
                              width: isExpanded ? 2.0 : 1.0,
                            ),
                            boxShadow: isExpanded
                                ? [
                                    BoxShadow(
                                      color: trackColor.withValues(alpha: 0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    )
                                  ]
                                : [],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Expand card to show details
                                  setState(() {
                                    _expandedCard = isExpanded ? null : name;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // 🔵 Icon Container with subtle glow
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: trackColor.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              icon,
                                              color: trackColor,
                                              size: 26,
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // 📝 Exercise Name & Focus Target
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  target,
                                                  style: TextStyle(
                                                    color: Colors.blueGrey[400],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // 🎯 TARGET REPS BADGE
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              "$targetReps Reps",
                                              style: TextStyle(
                                                color: badgeColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // 📂 EXPANDABLE CONTENT (Prescription details & Start Button)
                                      AnimatedCrossFade(
                                        firstChild: const SizedBox.shrink(),
                                        secondChild: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 16),
                                            Divider(color: Colors.white.withValues(alpha: 0.08)),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    "Status: $tier",
                                                    style: TextStyle(
                                                      color: badgeColor,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    "Level: $level",
                                                    style: TextStyle(
                                                      color: Colors.blueGrey[300],
                                                      fontSize: 13,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.end,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (coachNote != null && coachNote.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0B0F19).withValues(alpha: 0.5),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.psychology, color: trackColor, size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        coachNote,
                                                        style: const TextStyle(
                                                          color: Colors.blueGrey,
                                                          fontSize: 12,
                                                          fontStyle: FontStyle.italic,
                                                          height: 1.4,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 16),

                                            // 🚀 START BUTTON FOR THIS MOVEMENT
                                            SizedBox(
                                              width: double.infinity,
                                              height: 48,
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  // Launch the camera with the specific exercise selection
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => WorkoutScreen(
                                                        workoutName: name,
                                                        injuryCategory: selectedInjury,
                                                        prescribedReps: targetReps,
                                                        currentLevel: level,
                                                        adaptationTier: tier,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: trackColor,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                icon: const Icon(Icons.play_arrow, size: 20),
                                                label: const Text(
                                                  "Start AI Session",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                        duration: const Duration(milliseconds: 250),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
