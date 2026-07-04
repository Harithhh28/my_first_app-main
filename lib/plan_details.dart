import 'package:flutter/material.dart';
import 'workout_selection.dart';

class PlanDetailsScreen extends StatefulWidget {
  final String title;
  final String description;
  final List<String> bullets;
  final String durationInfo;
  final Color accentColor;

  const PlanDetailsScreen({
    super.key,
    required this.title,
    required this.description,
    required this.bullets,
    required this.durationInfo,
    required this.accentColor,
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

  // 🏥 Hardcoded 1-Month Dummy Data for FYP Presentation
  List<Map<String, dynamic>> _generateOneMonthPlan() {
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

  @override
  Widget build(BuildContext context) {
    final planData = _generateOneMonthPlan();

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
                              Text(
                                b,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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

                          final commitButton = ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${widget.title} Activated!"),
                                  backgroundColor: widget.accentColor,
                                ),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const WorkoutSelectionScreen(),
                                ),
                              );
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
                            bool isDone = day["completed"];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isDone
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isDone
                                        ? widget.accentColor
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          day["day"],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          day["details"],
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
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
