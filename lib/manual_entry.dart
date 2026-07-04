import 'package:flutter/material.dart';
import 'database_service.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  _ManualEntryScreenState createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  String _selectedWorkout = 'Squats';
  int _reps = 10;
  double _formScore = 80; // Self-assessed
  double _painLevel = 0;
  bool _isSaving = false;

  final List<String> _workouts = [
    'Squats',
    'Push-ups',
    'Lateral Raises',
    'Lunges',
  ];

  void _saveWorkout() async {
    setState(() => _isSaving = true);

    // Save the manual entry to Firebase
    await DatabaseService().saveWorkout(
      _selectedWorkout,
      _reps,
      _formScore.toInt(),
      painLevel: _painLevel.toInt(),
      // We leave detailedScores empty since the AI didn't track it!
    );

    if (mounted) {
      Navigator.pop(context); // Go back to Dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Workout logged manually!"),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: Text(
          "Log Workout",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏋️ WORKOUT SELECTION
            Text(
              "Exercise",
              style: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedWorkout,
                  dropdownColor: Color(0xFF1E293B),
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.blueGrey[400],
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedWorkout = newValue!;
                    });
                  },
                  items: _workouts.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 32),

            // 🔢 REP COUNTER
            Text(
              "Total Reps",
              style: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (_reps > 0) setState(() => _reps--);
                    },
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: Colors.blueGrey[300],
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 24),
                  Text(
                    "$_reps",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 24),
                  IconButton(
                    onPressed: () => setState(() => _reps++),
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF4353FF),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // 🎯 SELF-ASSESSED FORM SCORE
            Text(
              "Estimated Form Quality: ${_formScore.toInt()}%",
              style: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
            ),
            SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Color(0xFF4353FF),
                inactiveTrackColor: Color(0xFF1E293B),
                thumbColor: Colors.white,
                trackHeight: 8,
              ),
              child: Slider(
                value: _formScore,
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: (value) => setState(() => _formScore = value),
              ),
            ),
            SizedBox(height: 32),

            // 🤕 PAIN LOGGER
            Text(
              "Joint Pain Level: ${_painLevel.toInt()}/10",
              style: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
            ),
            SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _painLevel > 6
                    ? Colors.redAccent
                    : _painLevel > 3
                    ? Colors.orange
                    : Color(0xFF10B981),
                inactiveTrackColor: Color(0xFF1E293B),
                thumbColor: Colors.white,
                trackHeight: 8,
              ),
              child: Slider(
                value: _painLevel,
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (value) => setState(() => _painLevel = value),
              ),
            ),
            SizedBox(height: 48),

            // ✅ SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4353FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Log Workout",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
