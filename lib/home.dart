import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'database_service.dart';
import 'plan_details.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _injuryController = TextEditingController();
  bool _isGenerating = false;

  // This will store the AI generated plan once it finishes
  Map<String, dynamic>? _generatedPlan;

  // 📊 Dynamic stats loaded from Firestore in real-time
  int _streak = 0;
  int _recoveryPct = 0;
  List<bool> _weekDays = List.filled(7, false);
  String _userName = "";
  bool _statsLoaded = false;

  StreamSubscription? _workoutsSub;
  StreamSubscription? _profileSub;

  @override
  void initState() {
    super.initState();
    _initRealtimeListeners();
  }

  void _initRealtimeListeners() {
    final db = DatabaseService();

    // Listen to user profile updates (name, etc.)
    _profileSub = db.getUserProfile().listen((profileSnap) {
      final profileData = profileSnap.data() as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _userName = profileData?['name'] as String? ?? "";
        });
      }
    }, onError: (err) {
      debugPrint("Error listening to profile: $err");
    });

    // Listen to workouts changes to calculate streak + recovery in real time
    _workoutsSub = db.getUserWorkouts().listen((snapshot) {
      final workouts = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      final stats = db.calculateStreakAndRecoveryFromList(workouts);
      if (mounted) {
        setState(() {
          _streak      = stats['streak'] as int? ?? 0;
          _recoveryPct = stats['recovery'] as int? ?? 0;
          _weekDays    = List<bool>.from(stats['weekDays'] as List? ?? []);
          _statsLoaded = true;
        });
      }
    }, onError: (err) {
      debugPrint("Error listening to workouts: $err");
      if (mounted) {
        setState(() {
          _statsLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _workoutsSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  // 🧠 THE PROMPT ENGINEERING ENGINE
  Future<void> _generateDynamicPlan() async {
    final injuryText = _injuryController.text.trim();
    if (injuryText.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _generatedPlan = null; // Clear previous plan
    });

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.1-flash-lite',
        systemInstruction: Content.text(
          "You are a clinical physical therapist AI. "
          "The user will describe their injury. Generate a safe, progressive multi-week physical therapy plan. "
          "Respond ONLY with a single valid JSON object — no markdown, no code fences, no extra text. "
          "The JSON must have these exact keys: "
          "'title' (String, e.g., 'Ankle Sprain Recovery'), "
          "'injuryArea' (String — the main body part, e.g., 'Ankle', 'Knee', 'Shoulder', 'Lower Back', 'Hip'), "
          "'description' (String, brief clinical context, 1-2 sentences), "
          "'duration' (String, e.g., '4 WEEKS | 15 MIN/DAY'), "
          "'bullets' (List of exactly 3 short goal strings), "
          "'weeks' (List of exactly 4 week objects). "
          "Each week object has: 'week' (String, e.g., 'WEEK 1') and "
          "'days' (List of exactly 3 day objects). "
          "Each day object has: "
          "'day' (String, e.g., 'Day 1 - 15 Min'), "
          "'focus' (String, one-line theme e.g., 'Mobility & Swelling Reduction'), "
          "'exercises' (List of 2-4 exercise objects). "
          "Each exercise object has: "
          "'name' (String — a SHORT exercise name using plain words the camera AI can detect, "
          "e.g., 'Squats', 'Ankle Dorsiflexion', 'Shoulder Raise', 'Leg Raise', 'Calf Raise', 'Bicep Curl'), "
          "'sets' (int), "
          "'reps' (int), "
          "'notes' (String, brief coaching tip). "
          "Make exercises PROGRESSIVELY HARDER across weeks. "
          "Days within the same week should target DIFFERENT movement patterns "
          "(e.g., Day 1 = strength, Day 2 = balance/stability, Day 3 = flexibility/ROM). "
          "Do not repeat the same exercise on consecutive days."
        ),
      );

      final response = await model.generateContent([Content.text(injuryText)]);
      final responseText = response.text?.trim() ?? "{}";
      
      // Parse the JSON string Gemini gives us back into a Dart Map
      setState(() {
        _generatedPlan = jsonDecode(responseText);
        _isGenerating = false;
      });

    } catch (e) {
      debugPrint("AI Generation Error: $e");
      setState(() {
        _isGenerating = false;
        // Fallback in case of API failure
        _generatedPlan = {
          "title": "Custom Recovery Protocol",
          "description": "System encountered an error parsing the AI response. Defaulting to general mobility.",
          "duration": "4 WEEKS | 20 MIN/DAY",
          "bullets": ["General Mobility", "Pain Monitoring", "Joint Stability"],
          "weeks": [
            {
              "week": "WEEK 1",
              "days": [
                {"day": "Day 1 - 15 Min", "details": "10x ankle circles + light range of motion (3 sets)"},
                {"day": "Day 2 - 15 Min", "details": "10x wall stretch and isometric holds (3 sets)"}
              ]
            },
            {
              "week": "WEEK 2",
              "days": [
                {"day": "Day 1 - 20 Min", "details": "12x single-leg balance reach (3 sets)"},
                {"day": "Day 2 - 20 Min", "details": "12x light calf raises (3 sets)"}
              ]
            }
          ]
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090C14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌅 1. GREETING & PROFILE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Good Morning 👋", style: TextStyle(color: Colors.blueGrey[400], fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(_userName.isEmpty ? "Welcome!" : _userName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF1E293B),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 📊 2. AI RECOVERY SCORE & STREAK (Keeping this from before)
              Row(
                children: [
                  Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A2E),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.3), width: 2),
                      boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withValues(alpha: 0.1), blurRadius: 20)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _statsLoaded ? "$_recoveryPct%" : "--",
                          style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        Text("Recovery", style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _statsLoaded ? "$_streak Day${_streak == 1 ? '' : 's'} Streak" : "-- Day Streak",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final bool done = _statsLoaded && index < _weekDays.length && _weekDays[index];

                            // Calculate the day of the week label (e.g. M, T, W, T, F, S, S)
                            final day = DateTime.now().toLocal().subtract(Duration(days: 6 - index));
                            final weekdayLabel = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12, height: 32,
                                  decoration: BoxDecoration(
                                    color: done ? Colors.orangeAccent : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  weekdayLabel,
                                  style: TextStyle(
                                    color: done ? Colors.orangeAccent : Colors.blueGrey[600],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _streak >= 7 ? "🏆 7-Day Milestone reached!" : "Next Milestone: ${7 - _streak} days to go",
                          style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 🤖 3. DYNAMIC AI PLAN GENERATOR
              const Text("AI Plan Generator", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Describe your injury or pain, and the AI will build a custom recovery roadmap.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 13)),
              const SizedBox(height: 16),

              // Input Field
              TextField(
                controller: _injuryController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "E.g., I tweaked my lower back deadlifting yesterday. It hurts when I bend forward.",
                  hintStyle: TextStyle(color: Colors.blueGrey[600]),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF4353FF)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateDynamicPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4353FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isGenerating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                  label: Text(
                    _isGenerating ? "Analyzing Injury..." : "Generate Custom Plan", 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 🎯 4. THE GENERATED PLAN RESULT CARD
              if (_generatedPlan != null) 
                _buildGeneratedPlanCard(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🛠️ COMPONENT: The Generated AI Plan Card
  Widget _buildGeneratedPlanCard() {
    String title       = _generatedPlan!['title'] ?? "Custom Protocol";
    String description = _generatedPlan!['description'] ?? "AI personalized regimen.";
    String duration    = _generatedPlan!['duration'] ?? "TBD";
    String injuryArea  = _generatedPlan!['injuryArea'] ?? "";
    List<dynamic> bulletsDynamic = _generatedPlan!['bullets'] ?? [];
    List<String> bullets = bulletsDynamic.map((e) => e.toString()).toList();
    List<dynamic>? customWeeks = _generatedPlan!['weeks'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanDetailsScreen(
              title: title,
              description: description,
              bullets: bullets,
              durationInfo: duration,
              accentColor: const Color(0xFFFACC15),
              customWeeks: customWeeks,
              injuryArea: injuryArea,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A210F), Color(0xFF3B2F10)], // Yellow-ish dark gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFACC15).withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFFACC15), size: 18),
                    SizedBox(width: 8),
                    Text("AI GENERATED", style: TextStyle(color: Color(0xFFFACC15), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("New", style: TextStyle(color: Color(0xFFFACC15), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.4)),
            const SizedBox(height: 16),
            
            ...bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Color(0xFFFACC15), size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(b, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(duration.toUpperCase(), style: const TextStyle(color: Color(0xFFFACC15), fontSize: 12, fontWeight: FontWeight.bold)),
                const Icon(Icons.arrow_forward, color: Color(0xFFFACC15), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
