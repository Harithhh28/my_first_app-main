import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart'; // 👈 Added Gemini Import
import 'database_service.dart';

class SummaryScreen extends StatefulWidget {
  final String injuryCategory; // e.g., "Shoulder Recovery"
  final String workoutName;
  final int reps;
  final int formScore;
  final int prescribedReps;
  final String currentLevel;
  final String adaptationTier;

  const SummaryScreen({
    super.key,
    required this.injuryCategory,
    required this.workoutName,
    required this.reps,
    required this.formScore,
    required this.prescribedReps,
    required this.currentLevel,
    required this.adaptationTier,
  });

  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  double _painLevel = 0;
  bool _isSaving = false;

  // Deterministic Engine Variables
  late int _nextReps;
  late String _adaptationTier;
  late String _targetLevel;
  late String _coachNote;

  // 💬 Generative AI Variables
  String _aiEncouragement = "Analyzing your biometric data...";
  bool _isAiLoading = true;

  @override
  void initState() {
    super.initState();
    _runAdaptiveEngine();
    _generateAiAssessment(); // 👈 Call Gemini automatically when the screen loads!
  }

  // 🧠 THE DETERMINISTIC ADAPTIVE ENGINE
  void _runAdaptiveEngine() {
    int score = widget.formScore;
    int pain = _painLevel.toInt();
    int currentBase = widget.reps;

    if (currentBase == 0) {
      _adaptationTier = "NO ACTIVITY DETECTED";
      _nextReps = widget.prescribedReps;
      _targetLevel = widget.currentLevel;
      _coachNote =
          "No workout activity was detected during this session. Please perform the movements in front of the camera so the AI can track your reps and form.";
    } else if (score < 70 || pain > 6) {
      _adaptationTier = "REGRESSION DIALED";
      _nextReps = (currentBase - 2).clamp(4, 10);
      _targetLevel = "Light Level / Protected Range";
      _coachNote =
          "Form limitations or joint discomfort detected. Lowering volume to protect the structural integrity of your tissues.";
    } else if (score >= 85 && pain <= 3) {
      _adaptationTier = "PROGRESSION GRANTED";
      if (currentBase >= 12) {
        _nextReps = 10;
        _targetLevel = "Intermediate Modification Tier";
        _coachNote =
            "Superb neuromuscular control. Upgrading your movement mechanics to intermediate variations.";
      } else {
        _nextReps = currentBase + 2;
        _targetLevel = "Increased Adaptive Volume";
        _coachNote =
            "Movement symmetry verified. Increasing target parameters to foster tissue adaptation.";
      }
    } else {
      _adaptationTier = "MAINTENANCE ACTIVE";
      _nextReps = currentBase;
      _targetLevel = "Current Base Tier";
      _coachNote =
          "Safe motor mechanics achieved. Keeping parameters baseline to solidify joint stabilization.";
    }
  }

  // 💬 THE GENERATIVE AI COACH (GEMINI)
  Future<void> _generateAiAssessment() async {
    setState(() => _isAiLoading = true);

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.1-flash-lite',
        systemInstruction: Content.text(
          "You are 'Rehab Ai Coach', a clinical physical therapist. "
          "Keep your answer to exactly 2 or 3 short sentences. "
          "Be highly empathetic and encouraging. Give one quick post-workout recovery tip.",
        ),
      );

      final String prompt;
      if (widget.reps == 0) {
        prompt =
            "My patient started a ${widget.workoutName} session for their ${widget.injuryCategory} but completed 0 reps. "
            "They reported a pain level of ${_painLevel.toInt()} out of 10. "
            "Write a highly empathetic message asking why they couldn't perform the workout (e.g. if they had too much pain or stiffness), "
            "encouraging them to listen to their body, and suggesting a very gentle rest or recovery tip (such as applying ice or heat).";
      } else {
        prompt =
            "My patient just finished a ${widget.workoutName} protocol for their ${widget.injuryCategory}. "
            "They completed ${widget.reps} reps with a machine-vision form score of ${widget.formScore}%. "
            "They reported a pain level of ${_painLevel.toInt()} out of 10. "
            "The patient's ultimate clinical goal is to 'Return to Running'. " // 👈 NEW PERSONALIZATION LAYER
            "The system engine classified their next session as: $_adaptationTier. "
            "Please give them a brief, encouraging summary and a quick recovery tip based on these specific numbers and their ultimate goal.";
      }

      final response = await model.generateContent([Content.text(prompt)]);

      if (mounted) {
        setState(() {
          _aiEncouragement =
              response.text?.trim() ??
              (widget.reps == 0
                  ? "It looks like you didn't complete any reps today. Remember to listen to your body—rest is just as important as exercise. Let us know if you need to adjust your protocol."
                  : "Great job today. Make sure to hydrate and rest the joint.");
          _isAiLoading = false;
        });
      }
    } catch (e) {
      debugPrint("AI Assessment Error: $e");
      if (mounted) {
        setState(() {
          _aiEncouragement = widget.reps == 0
              ? "It looks like you didn't complete any reps today. Remember to listen to your body—rest is just as important as exercise. Let us know if you need to adjust your protocol."
              : "Incredible work pushing through your protocol today! Ensure you get plenty of rest and hydrate to aid tissue recovery.";
          _isAiLoading = false;
        });
      }
    }
  }

  void _saveAndCommit() async {
    if (widget.reps > 0) {
      setState(() => _isSaving = true);

      await DatabaseService().saveAdaptiveWorkout(
        injuryCategory: widget.injuryCategory,
        workoutName: widget.workoutName,
        repsCompleted: widget.reps,
        formScore: widget.formScore,
        painLevel: _painLevel.toInt(),
        nextPrescribedReps: _nextReps,
        targetLevel: _targetLevel,
        adaptationTier: _adaptationTier,
        coachNote: _coachNote,
      );
    }

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color tierColor = _adaptationTier.contains("PROGRESSION")
        ? const Color(0xFF4ADE80)
        : _adaptationTier.contains("REGRESSION")
        ? const Color(0xFFF87171)
        : const Color(0xFFFACC15);

    return Scaffold(
      backgroundColor: const Color(0xFF090C14),
      appBar: AppBar(
        title: const Text(
          "Session Report",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Protocol Completed",
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.workoutName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // 📊 1. SESSION STATS
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      "Completed Vol",
                      "${widget.reps} Reps",
                      Colors.white,
                      Icons.fitness_center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricTile(
                      "AI Form Rating",
                      "${widget.formScore}%",
                      tierColor,
                      Icons.analytics,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 🤖 2. THE GENERATIVE AI COACH ASSESSMENT
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4353FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.psychology,
                          color: Color(0xFF4353FF),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Coach's Assessment",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isAiLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Color(0xFF4353FF),
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _aiEncouragement,
                      style: TextStyle(
                        color: Colors.blueGrey[100],
                        fontSize: 15,
                        height: 1.5,
                        fontStyle: _isAiLoading
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🧠 3. CLINICAL ADAPTATION (Math Engine)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF131A2E), Color(0xFF1E294B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: tierColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tierColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _adaptationTier,
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Next Target: $_nextReps Reps",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Class: $_targetLevel",
                      style: TextStyle(
                        color: Colors.blueGrey[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 🤕 4. PAIN LOGGER
              Text(
                "Joint Discomfort Level",
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Report Level",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          "${_painLevel.toInt()} / 10",
                          style: TextStyle(
                            color: _painLevel > 6
                                ? const Color(0xFFF87171)
                                : _painLevel > 3
                                ? const Color(0xFFFACC15)
                                : const Color(0xFF4ADE80),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _painLevel > 6
                            ? const Color(0xFFF87171)
                            : _painLevel > 3
                            ? const Color(0xFFFACC15)
                            : const Color(0xFF4ADE80),
                        inactiveTrackColor: const Color(0xFF1E293B),
                        thumbColor: Colors.white,
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: _painLevel,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        onChanged: (val) {
                          setState(() {
                            _painLevel = val;
                            _runAdaptiveEngine();
                            // 💡 Optional: You could call _generateAiAssessment() here again to re-prompt the AI if pain changes, but it uses extra API tokens!
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // ✅ COMMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAndCommit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.reps > 0
                        ? const Color(0xFF4353FF)
                        : Colors.blueGrey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox.shrink()
                      : Icon(
                          widget.reps > 0 ? Icons.check_circle : Icons.home,
                          color: Colors.white,
                        ),
                  label: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.reps > 0
                              ? "Commit to Recovery Log"
                              : "Return to Home",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    Color dataColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey[500], size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: dataColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
