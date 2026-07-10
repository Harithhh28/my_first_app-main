import 'package:flutter/material.dart';
import 'database_service.dart';
import 'workout.dart';

class PlanDetailsScreen extends StatefulWidget {
  final String title;
  final String description;
  final List<String> bullets;
  final String durationInfo;
  final Color accentColor;
  final List<dynamic>? customWeeks;
  final String injuryArea; // e.g. "Knee", "Ankle", "Shoulder"
  final bool showCommitButton;

  const PlanDetailsScreen({
    super.key,
    required this.title,
    required this.description,
    required this.bullets,
    required this.durationInfo,
    required this.accentColor,
    this.customWeeks,
    this.injuryArea = '',
    this.showCommitButton = false,
  });

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _activeWeek = 0; // 0-indexed: 0 = W1, 1 = W2, etc.

  // Approximate scroll offsets where each week section starts
  // header ~320px, then each week ~180px
  final List<double> _weekOffsets = [0, 320, 520, 700];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      int newWeek = 0;
      for (int i = _weekOffsets.length - 1; i >= 0; i--) {
        if (offset >= _weekOffsets[i] - 60) {
          newWeek = i;
          break;
        }
      }
      if (newWeek != _activeWeek) {
        setState(() => _activeWeek = newWeek);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🏥 Hardcoded Static Syllabi for Rehab Plans
  List<Map<String, dynamic>> _generateStaticSyllabus(String title) {
    if (title.contains("Knee")) {
      return [
        {
          "week": "WEEK 1",
          "days": [
            {
              "day": "Day 1 - 15 Min",
              "details": "Passive extension & quad sets (3 Sets)",
              "completed": false,
            },
            {
              "day": "Day 2 - 20 Min",
              "details": "Straight leg raises & heel slides (4 Sets)",
              "completed": false,
            },
            {
              "day": "Day 3 - 20 Min",
              "details": "Patella mobilization & gentle hamstring stretch",
              "completed": false,
            },
          ],
        },
        {
          "week": "WEEK 2",
          "days": [
            {
              "day": "Day 1 - 25 Min",
              "details": "Weighted quad extension + mini squats (3 Sets)",
              "completed": false,
            },
            {
              "day": "Day 2 - 25 Min",
              "details": "Closed kinetic chain exercises & balance holds (4 Sets)",
              "completed": false,
            },
            {
              "day": "Day 3 - 20 Min",
              "details": "Active range of motion knee bends",
              "completed": false,
            },
          ],
        },
        {
          "week": "WEEK 3",
          "days": [
            {
              "day": "Day 1 - 30 Min",
              "details": "Proprioceptive exercises & step downs (5 Sets)",
              "completed": false,
            },
            {
              "day": "Day 2 - 30 Min",
              "details": "Side-lying leg lifts & terminal knee extensions",
              "completed": false,
            },
          ],
        },
        {
          "week": "WEEK 4",
          "days": [
            {
              "day": "Day 1 - 35 Min",
              "details": "Eccentric single leg squats (5 Sets)",
              "completed": false,
            },
            {
              "day": "Day 2 - 35 Min",
              "details": "Functional agility drills & return-to-load assessment",
              "completed": false,
            },
          ],
        },
      ];
    } else if (title.contains("Mix")) {
      return [
        {
          "week": "WEEK 1",
          "days": [
            {
              "day": "Day 1 - 20 Min",
              "details": "Core activation & joint alignment exercises",
              "completed": false,
            },
            {
              "day": "Day 2 - 25 Min",
              "details": "Alternating upper/lower kinetic chain mobilizations",
              "completed": false,
            },
            {
              "day": "Day 3 - 20 Min",
              "details": "Low intensity steady state cardio or general walk",
              "completed": false,
            },
          ],
        },
        {
          "week": "WEEK 2",
          "days": [
            {
              "day": "Day 1 - 25 Min",
              "details": "Rotator cuff activation + balance stabilization (4 Sets)",
              "completed": false,
            },
            {
              "day": "Day 2 - 25 Min",
              "details": "Glute bridge holds & shoulder wall slides (4 Sets)",
              "completed": false,
            },
            {
              "day": "Day 3 - 20 Min",
              "details": "Total body active stretching sequence",
              "completed": false,
            },
          ],
        },
        {
          "week": "WEEK 3",
          "days": [
            {
              "day": "Day 1 - 30 Min",
              "details": "Dynamic movement control drills (5 Sets)",
              "completed": false,
            },
            {
              "day": "Day 2 - 30 Min",
              "details": "Plank taps & single leg balance reaches",
              "completed": false,
            },
          ],
        },
        {
          "week": "WEEK 4",
          "days": [
            {
              "day": "Day 1 - 35 Min",
              "details": "Full body conditioning & structural strength",
              "completed": false,
            },
            {
              "day": "Day 2 - 35 Min",
              "details": "Progressive multi-planar loading protocol",
              "completed": false,
            },
          ],
        },
      ];
    } else {
      // Default: Shoulder Recovery
      return [
        {
          "week": "WEEK 1",
          "days": [
            {
              "day": "Day 1 - 15 Min",
              "details": "10x Light Reps + 30s Mobility Hold (3 Sets)",
              "completed": false,
            },
            {
              "day": "Day 2 - 20 Min",
              "details": "12x Stabilizer Work + AI Form Check (4 Sets)",
              "completed": false,
            },
            {
              "day": "Day 3 - 20 Min",
              "details": "Active Recovery Stretch & Mobility (2 Sets)",
              "completed": false,
            },
          ],
        },
        {
          "week": "WEEK 2",
          "days": [
            {
              "day": "Day 1 - 25 Min",
              "details": "10x Resistance Band + Iso Holds (4 Sets)",
              "completed": false,
            },
            {
              "day": "Day 2 - 25 Min",
              "details": "15x Volume Build & Asymmetry Check (4 Sets)",
              "completed": false,
            },
            {
              "day": "Day 3 - 20 Min",
              "details": "Joint Decompression Stretches (3 Sets)",
              "completed": false,
            },
          ],
        },
        {
          "week": "WEEK 3",
          "days": [
            {
              "day": "Day 1 - 30 Min",
              "details": "Intermediate Load Integration (5 Sets)",
              "completed": false,
            },
            {
              "day": "Day 2 - 30 Min",
              "details": "Neuromuscular Control Protocol (5 Sets)",
              "completed": false,
            },
          ],
        },
        {
          "week": "WEEK 4",
          "days": [
            {
              "day": "Day 1 - 35 Min",
              "details": "Full Range of Motion Stress Test (5 Sets)",
              "completed": false,
            },
            {
              "day": "Day 2 - 35 Min",
              "details": "Pre-Discharge Strength Assessment (5 Sets)",
              "completed": false,
            },
          ],
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final planData = widget.customWeeks ?? _generateStaticSyllabus(widget.title);

    return Scaffold(
      backgroundColor: const Color(0xFF090C14),
      body: Stack(
        children: [
          // 📜 MAIN SCROLLABLE CONTENT
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🌉 HEADER SECTION
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 60,
                    left: 24,
                    right: 24,
                    bottom: 32,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF090C14)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Close Button
                      Align(
                        alignment: Alignment.topRight,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        widget.description,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bullets
                      ...widget.bullets.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  b,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Duration & Commit Button Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final bool useColumn = constraints.maxWidth < 340;

                          final durationText = Text(
                            widget.durationInfo.toUpperCase(),
                            style: TextStyle(
                              color: widget.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );

                          if (!widget.showCommitButton) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                durationText,
                                const Text(
                                  "ACTIVE PROTOCOL",
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          }

                          final commitButton = ElevatedButton.icon(
                            onPressed: () async {
                              // Save the plan to history database
                              await DatabaseService().saveCustomPlan(
                                title: widget.title,
                                description: widget.description,
                                bullets: widget.bullets,
                                durationInfo: widget.durationInfo,
                                customWeeks: widget.customWeeks,
                              );

                              // Mark it as active in Firestore
                              await DatabaseService().setActivePlan(widget.title);

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${widget.title} Activated!"),
                                  backgroundColor: widget.accentColor,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.accentColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.star, size: 18),
                            label: const Text(
                              "Commit to this plan",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );

                          if (useColumn) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                durationText,
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: commitButton,
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                durationText,
                                commitButton,
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // 🗓️ WEEK BY WEEK LIST
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: planData.map((week) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          Text(
                            week["week"],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...week["days"].map<Widget>((day) {
                            final bool isDone = day["completed"] == true;
                            // Support both new structure (exercises list) and old (details string)
                            final List<dynamic> exercises = day["exercises"] as List<dynamic>? ?? [];
                            final String focus = day["focus"] as String? ?? "";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111827),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDone
                                      ? widget.accentColor.withValues(alpha: 0.5)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Icon(
                                  isDone ? Icons.check_circle : Icons.circle_outlined,
                                  color: isDone ? widget.accentColor : Colors.grey[600],
                                  size: 22,
                                ),
                                title: Text(
                                  day["day"] ?? "Day",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: focus.isNotEmpty
                                    ? Text(
                                        focus,
                                        style: TextStyle(color: widget.accentColor, fontSize: 12),
                                      )
                                    : null,
                                // Show old-style details as fallback
                                children: exercises.isNotEmpty
                                    ? exercises.map<Widget>((ex) {
                                        final String exName  = ex["name"]  as String? ?? "Exercise";
                                        final int    sets    = (ex["sets"]  as num?)?.toInt() ?? 3;
                                        final int    reps    = (ex["reps"]  as num?)?.toInt() ?? 10;
                                        final String notes   = ex["notes"] as String? ?? "";

                                        return ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                                          leading: Container(
                                            width: 40, height: 40,
                                            decoration: BoxDecoration(
                                              color: widget.accentColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.fitness_center, color: widget.accentColor, size: 18),
                                          ),
                                          title: Text(
                                            exName,
                                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "$sets sets × $reps reps",
                                                style: TextStyle(color: widget.accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              if (notes.isNotEmpty)
                                                Text(notes, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                            ],
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.play_circle_fill, color: Color(0xFF4353FF), size: 32),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => WorkoutScreen(
                                                    workoutName: exName,
                                                    injuryCategory: widget.injuryArea.isNotEmpty
                                                        ? widget.injuryArea
                                                        : widget.title,
                                                    prescribedReps: reps,
                                                    planTitle: widget.title,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      }).toList()
                                    : [
                                        // Fallback for old-format plans with 'details' string
                                        ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                          title: Text(
                                            day["details"] ?? "",
                                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.play_circle_fill, color: Color(0xFF4353FF), size: 32),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => WorkoutScreen(
                                                    workoutName: day["details"] ?? day["day"] ?? "Rehab Exercise",
                                                    injuryCategory: widget.injuryArea.isNotEmpty
                                                        ? widget.injuryArea
                                                        : widget.title,
                                                    prescribedReps: 10,
                                                    planTitle: widget.title,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),

          // 🔢 RIGHT SIDE DYNAMIC SCROLL INDEX (W1–W4)
          Positioned(
            right: 12,
            top: MediaQuery.of(context).size.height * 0.45,
            child: Column(
              children: List.generate(4, (i) {
                final isActive = _activeWeek == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: GestureDetector(
                    onTap: () {
                      // Tap to jump to that week
                      _scrollController.animateTo(
                        _weekOffsets[i],
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        color: isActive
                            ? widget.accentColor
                            : Colors.grey[700]!,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: isActive ? 14 : 11,
                      ),
                      child: Text("W${i + 1}"),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
