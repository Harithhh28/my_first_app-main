import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class RomAssessmentScreen extends StatefulWidget {
  const RomAssessmentScreen({super.key});

  @override
  _RomAssessmentScreenState createState() => _RomAssessmentScreenState();
}

class _RomAssessmentScreenState extends State<RomAssessmentScreen> {
  // Sensor Variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _currentAngle = 0.0;
  double _maxAngle = 0.0;
  bool _isMeasuring = false;

  // Start reading the sensor data
  void _startMeasurement() {
    setState(() {
      _isMeasuring = true;
      _maxAngle = 0.0; // Reset max angle for new measurement
    });

    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      // 🧮 THE MATH: Calculate the tilt angle relative to gravity
      // Depending on how the phone is held, we calculate pitch/roll. 
      // This formula calculates the vertical tilt of the phone.
      double y = event.y;
      double z = event.z;
      
      // Convert radians to degrees
      double angle = (atan2(y, z) * 180 / pi);
      
      // Normalize angle to be between 0 and 180 for easy reading
      if (angle < 0) angle = angle + 180;
      if (angle > 90 && y < 0) angle = 180 - angle;

      setState(() {
        _currentAngle = angle.abs();
        if (_currentAngle > _maxAngle) {
          _maxAngle = _currentAngle; // Lock in the highest angle achieved
        }
      });
    });
  }

  // Stop reading the sensor data
  void _stopMeasurement() {
    _accelerometerSubscription?.cancel();
    setState(() {
      _isMeasuring = false;
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090C14),
      appBar: AppBar(
        title: const Text("Range of Motion Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Instructions
              Text(
                "Shoulder Elevation Test",
                style: TextStyle(color: Colors.blueGrey[300], fontSize: 16, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              const Text(
                "Hold your phone flat against your arm and slowly raise it as high as you can.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 60),

              // 📐 THE LIVE ANGLE DISPLAY
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: _currentAngle / 180, // Fills up as you reach 180 degrees
                      strokeWidth: 12,
                      backgroundColor: const Color(0xFF1E293B),
                      color: const Color(0xFF4353FF),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${_currentAngle.toInt()}°",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Current Angle",
                        style: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 🏆 MAX ANGLE ACHIEVED (THE RESULT)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFF4ADE80)),
                    const SizedBox(width: 12),
                    Text(
                      "Max Achieved: ${_maxAngle.toInt()}°",
                      style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // 🚀 START / STOP BUTTON
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _isMeasuring ? _stopMeasurement : _startMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMeasuring ? Colors.redAccent : const Color(0xFF4353FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(_isMeasuring ? Icons.stop_circle : Icons.play_circle_fill, color: Colors.white),
                  label: Text(
                    _isMeasuring ? "Stop Measurement" : "Start Sensor",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
