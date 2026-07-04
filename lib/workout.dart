import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'main.dart'; // To access the global 'cameras' list
import 'pose_painter.dart'; // For rendering the stick figure
import 'summary.dart';

class WorkoutScreen extends StatefulWidget {
  final String workoutName;
  final String injuryCategory;
  final int prescribedReps;
  final String currentLevel;
  final String adaptationTier;
  final String? planTitle;

  const WorkoutScreen({
    super.key,
    this.workoutName = "Active Workout",
    this.injuryCategory = "Knee",
    this.prescribedReps = 10,
    this.currentLevel = "Volume Initial",
    this.adaptationTier = "Baseline",
    this.planTitle,
  });

  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isFinished = false;

  // 👇 1. INITIALIZE THE AI BRAIN
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );
  bool _isProcessing = false;
  String _aiStatus = "Warming up the AI...";

  // 🧍‍♂️ Stick figure data
  List<Pose>? _poses;
  Size? _imageSize;
  InputImageRotation? _rotation;

  // 📊 WORKOUT STATS
  int _reps = 0;
  int _formScore = 100;
  int _totalLeftScore = 0;
  int _totalRightScore = 0;
  int _leftKneeFinal = 100;
  int _rightKneeFinal = 100;

  // 🏋️‍♀️ REP TRACKING STATE
  bool _isArmDown = true;
  final int _totalScore = 0;
  double _repMaxSway = 0.0;

  // Helper for camera rotation
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // Calculates the angle at the 'middle' joint
  double _calculateAngle(
    PoseLandmark first,
    PoseLandmark middle,
    PoseLandmark last,
  ) {
    double angle =
        math.atan2(last.y - middle.y, last.x - middle.x) -
        math.atan2(first.y - middle.y, first.x - middle.x);

    angle = angle * (180.0 / math.pi); // Convert radians to degrees

    if (angle < 0) {
      angle += 360.0;
    }
    if (angle > 180) {
      angle = 360 - angle;
    }
    return angle;
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.low, // Lower resolution is faster for AI
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    // 👇 2. FEED LIVE FRAMES TO THE AI
    _controller!.startImageStream((CameraImage image) {
      if (!_isProcessing && !_isFinished) {
        _processImage(image, frontCamera);
      }
    });

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  // 👇 3. THE AI PROCESSING LOOP
  // 👇 3. THE AI PROCESSING LOOP (UPDATED FOR SQUATS)
  Future<void> _processImage(
    CameraImage image,
    CameraDescription camera,
  ) async {
    _isProcessing = true;
    try {
      final inputImage = _inputImageFromCameraImage(image, camera);
      if (inputImage == null) return;

      // 🧠 Ask ML Kit to find human bodies in the frame
      final List<Pose> poses = await _poseDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _poses = poses;
          _imageSize = inputImage.metadata?.size;
          _rotation = inputImage.metadata?.rotation;

          if (poses.isEmpty) {
            _aiStatus = "Step back into the frame.";
          } else {
            final pose = poses.first;

            // 1. GET THE SQUAT JOINTS (Hips, Knees, Ankles)
            final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
            final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
            final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

            final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
            final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
            final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

            // 2. Make sure the AI can see the lower body
            if (leftHip != null &&
                leftKnee != null &&
                leftAnkle != null &&
                rightHip != null &&
                rightKnee != null &&
                rightAnkle != null) {
              // 3. Calculate INDEPENDENT squat depths
              double leftSquatAngle = _calculateAngle(
                leftHip,
                leftKnee,
                leftAnkle,
              );
              double rightSquatAngle = _calculateAngle(
                rightHip,
                rightKnee,
                rightAnkle,
              );

              // The average depth determines if the rep counts
              double avgSquatAngle = (leftSquatAngle + rightSquatAngle) / 2;

              // 4. Calculate ASYMMETRY (Are they leaning on one leg?)
              // If the difference in angles is high, they are shifting their weight!
              double difference = (leftSquatAngle - rightSquatAngle).abs();

              if (difference > _repMaxSway) {
                _repMaxSway = difference; // Re-using this to track worst lean
              }

              // 5. SQUAT REP COUNTING LOGIC
              if (avgSquatAngle > 160) {
                _isArmDown = true;
                _aiStatus = "Good, now squat DOWN!";
                _repMaxSway = 0.0; // Reset lean tracker
              } else if (avgSquatAngle < 100 && _isArmDown == true) {
                _reps++;
                _isArmDown = false;

                // --- ASYMMETRY FORM SCORE ---
                int repLeftScore = 100;
                int repRightScore = 100;

                // If they leaned heavily during the rep, punish the lazy leg!
                if (_repMaxSway > 20) {
                  // 20+ degree difference is a severe lean
                  _aiStatus = "Heavy shifting detected! Balance your weight.";
                  if (leftSquatAngle > rightSquatAngle) {
                    repLeftScore = 40; // Left leg didn't bend enough
                  } else {
                    repRightScore = 40; // Right leg didn't bend enough
                  }
                } else if (_repMaxSway > 10) {
                  _aiStatus = "Slight lean. Keep hips centered.";
                  if (leftSquatAngle > rightSquatAngle) {
                    repLeftScore = 75;
                  } else {
                    repRightScore = 75;
                  }
                } else {
                  _aiStatus = "Perfect symmetry! UP!";
                }

                // Add up the totals
                _totalLeftScore += repLeftScore;
                _totalRightScore += repRightScore;

                // Calculate final averages
                _leftKneeFinal = (_totalLeftScore / _reps).round();
                _rightKneeFinal = (_totalRightScore / _reps).round();

                // Overall score is the average of both legs
                _formScore = ((_leftKneeFinal + _rightKneeFinal) / 2).round();

                // Check if they finished the prescribed reps!
                if (_reps >= widget.prescribedReps) {
                  _aiStatus = "Target reached! Finishing workout...";
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _finishWorkout();
                  });
                }
              }
            } else {
              _aiStatus = "I can't see your hips, knees and ankles!";
            }
          }
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _finishWorkout() {
    if (_isFinished) return;
    _isFinished = true;

    // 1. Stop the camera to free up memory
    _controller?.stopImageStream();

    // 2. Navigate to Summary Screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryScreen(
            injuryCategory: widget.injuryCategory,
            workoutName: widget.workoutName,
            reps: _reps,
            formScore: _reps > 0 ? _formScore : 0,
            prescribedReps: widget.prescribedReps,
            currentLevel: widget.currentLevel,
            adaptationTier: widget.adaptationTier,
          ),
        ),
      );
    }
  }

  // 👇 4. CONVERT CAMERA FEED FOR ML KIT
  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _poseDetector.close(); // Don't forget to kill the AI to save battery!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.workoutName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (widget.planTitle != null)
              Text(
                "Active Plan: ${widget.planTitle}",
                style: const TextStyle(color: Color(0xFFFACC15), fontSize: 12, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: _isCameraInitialized
          ? Stack(
              children: [
                // 🎥 THE LIVE CAMERA FEED WITH ASPECT RATIO CORRECTION
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      final double cameraAspectRatio = _controller!.value.aspectRatio;
                      final double portraitAspectRatio = 1 / cameraAspectRatio;

                      double scale = size.aspectRatio / portraitAspectRatio;
                      if (scale < 1.0) {
                        scale = 1.0 / scale;
                      }

                      return ClipRect(
                        child: Transform.scale(
                          scale: scale,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: portraitAspectRatio,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CameraPreview(_controller!),
                                  if (_poses != null && _imageSize != null && _rotation != null)
                                    CustomPaint(
                                      painter: PosePainter(
                                        _poses!,
                                        _imageSize!,
                                        _rotation!,
                                        _controller!.description.lensDirection,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 📊 REAL-TIME STATS OVERLAY
                Positioned(
                  top: 100, // Places it nicely below the AppBar
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBox("Reps", "$_reps"),
                      _buildStatBox("Form Score", "$_formScore%"),
                    ],
                  ),
                ),

                // 🤖 AI STATUS OVERLAY
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _aiStatus.contains("Sees You")
                              ? Icons.accessibility_new
                              : Icons.center_focus_strong,
                          color: _aiStatus.contains("Sees You")
                              ? Color(0xFF10B981)
                              : Color(0xFF4353FF),
                          size: 40,
                        ),
                        SizedBox(height: 12),
                        Text(
                          _aiStatus.contains("Sees You")
                              ? "Perfect, get ready to curl!"
                              : "Where are you?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _aiStatus,
                          style: TextStyle(
                            color: Colors.blueGrey[300],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 24),
                        // 👇 FINISH WORKOUT BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _finishWorkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFE50914), // Bold Red
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "FINISH WORKOUT",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator(color: Color(0xFF4353FF))),
    );
  }

  // Helper widget to draw the glassy stat boxes over the camera
  Widget _buildStatBox(String title, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.blueGrey[200],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
