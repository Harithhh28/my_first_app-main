import 'dart:io';
import 'dart:async';
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
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isFinished = false;
  bool _noCameraAvailable = false;
  Timer? _simulationTimer;

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
  double _repMaxSway = 0.0;

  // Helper for camera rotation
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // Calculates the angle at the 'middle' joint
  double _calculateAngle(PoseLandmark first, PoseLandmark middle, PoseLandmark last) {
    double angle = math.atan2(last.y - middle.y, last.x - middle.x) -
                   math.atan2(first.y - middle.y, first.x - middle.x);
    angle = angle * (180.0 / math.pi);
    if (angle < 0) angle += 360.0;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _startSimulatedWorkout() {
    _aiStatus = "Simulating movement (No camera detected)...";
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _isFinished) {
        timer.cancel();
        return;
      }
      setState(() {
        _reps++;
        _formScore = 90 + (5 * (timer.tick % 3));
        _aiStatus = "Simulating rep $_reps (Perfect Symmetry)";
        if (_reps >= widget.prescribedReps) {
          _aiStatus = "Target reached! Finishing workout...";
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 1000), () {
            _finishWorkout();
          });
        }
      });
    });
  }

  void _initializeCamera() async {
    if (cameras.isEmpty) {
      setState(() {
        _noCameraAvailable = true;
        _isCameraInitialized = true;
      });
      _startSimulatedWorkout();
      return;
    }

    try {
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

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
    } catch (e) {
      debugPrint("Camera initialization error: $e");
      setState(() {
        _noCameraAvailable = true;
        _isCameraInitialized = true;
      });
      _startSimulatedWorkout();
    }
  }

  // 🧠 Detect which exercise type to track based on the workout name
  String get _exerciseType {
    final name = widget.workoutName.toLowerCase();
    if (name.contains("squat") || name.contains("lunge") || name.contains("leg press")) {
      return "squat";
    } else if (name.contains("curl") || name.contains("bicep") || name.contains("elbow")) {
      return "curl";
    } else if (name.contains("shoulder") || name.contains("raise") || name.contains("press") || name.contains("overhead")) {
      return "shoulder";
    } else if (name.contains("ankle") || name.contains("calf") || name.contains("dorsi")) {
      return "ankle";
    } else if (name.contains("leg raise") || name.contains("straight leg") || name.contains("hip")) {
      return "leg_raise";
    }
    // Default: use upper-body (shoulder) tracking as a safe fallback
    return "general";
  }

  Future<void> _processImage(CameraImage image, CameraDescription camera) async {
    _isProcessing = true;
    try {
      final inputImage = _inputImageFromCameraImage(image, camera);
      if (inputImage == null) return;

      final List<Pose> poses = await _poseDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _poses = poses;
          _imageSize = inputImage.metadata?.size;
          _rotation = inputImage.metadata?.rotation;

          if (poses.isEmpty) {
            _aiStatus = "Step back into the frame.";
            return;
          }

          final pose = poses.first;
          final type = _exerciseType;

          if (type == "squat" || type == "ankle" || type == "leg_raise") {
            _trackLowerBody(pose, type);
          } else {
            _trackUpperBody(pose, type);
          }
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  // 🦵 Lower body tracker: squats, ankle work, leg raises
  void _trackLowerBody(Pose pose, String type) {
    final leftHip   = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee  = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip   = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee  = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || leftKnee == null || leftAnkle == null ||
        rightHip == null || rightKnee == null || rightAnkle == null) {
      _aiStatus = "Can't see your legs clearly. Step back.";
      return;
    }

    double leftAngle  = _calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);
    double avgAngle   = (leftAngle + rightAngle) / 2;
    double sway       = (leftAngle - rightAngle).abs();

    if (sway > _repMaxSway) { _repMaxSway = sway; }

    // Angle thresholds and coaching text differ per exercise
    final bool isStanding = avgAngle > 160;
    final bool isBent     = avgAngle < (type == "ankle" ? 140 : 100);
    final String downCue  = type == "squat"
        ? "Now squat DOWN slowly!"
        : type == "ankle"
            ? "Now flex your ankle gently."
            : "Raise your leg upward.";
    final String upCue    = type == "squat" ? "Drive UP through your heels!" : "Hold, then return slowly.";

    if (isStanding) {
      _isArmDown = true;
      _aiStatus  = downCue;
      _repMaxSway = 0.0;
    } else if (isBent && _isArmDown) {
      _reps++;
      _isArmDown = false;
      _scoreRep(sway, leftAngle > rightAngle, upCue);
    }
  }

  // 💪 Upper body tracker: bicep curls, shoulder raises
  void _trackUpperBody(Pose pose, String type) {
    final leftShoulder  = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow     = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist     = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow    = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist    = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null || leftElbow == null || leftWrist == null ||
        rightShoulder == null || rightElbow == null || rightWrist == null) {
      _aiStatus = "Can't see your arms clearly. Face the camera.";
      return;
    }

    // For shoulder: shoulder→elbow→hip angle; for curl: shoulder→elbow→wrist angle
    final leftHip  = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    double leftAngle;
    double rightAngle;

    if (type == "shoulder" && leftHip != null && rightHip != null) {
      leftAngle  = _calculateAngle(leftElbow,  leftShoulder,  leftHip);
      rightAngle = _calculateAngle(rightElbow, rightShoulder, rightHip);
    } else {
      leftAngle  = _calculateAngle(leftShoulder,  leftElbow,  leftWrist);
      rightAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
    }

    double avgAngle = (leftAngle + rightAngle) / 2;
    double sway     = (leftAngle - rightAngle).abs();
    if (sway > _repMaxSway) { _repMaxSway = sway; }

    final bool isDown  = avgAngle < 40;
    final bool isUp    = avgAngle > 140;
    final String downCue = type == "shoulder" ? "Lower your arms down." : "Lower the weight down.";
    final String upCue   = type == "shoulder" ? "Raise both arms — keep them level!" : "Curl UP — squeeze at the top!";

    if (isDown) {
      _isArmDown  = true;
      _aiStatus   = upCue;
      _repMaxSway = 0.0;
    } else if (isUp && _isArmDown) {
      _reps++;
      _isArmDown = false;
      _scoreRep(sway, leftAngle > rightAngle, downCue);
    }
  }

  // 📊 Shared rep scoring logic
  void _scoreRep(double sway, bool leftHigher, String nextCue) {
    int repLeftScore  = 100;
    int repRightScore = 100;

    if (sway > 20) {
      _aiStatus = "Heavy imbalance! ${leftHigher ? 'Right' : 'Left'} side is lagging.";
      if (leftHigher) { repRightScore = 40; } else { repLeftScore = 40; }
    } else if (sway > 10) {
      _aiStatus = "Slight asymmetry — try to keep both sides even.";
      if (leftHigher) { repRightScore = 75; } else { repLeftScore = 75; }
    } else {
      _aiStatus = "Perfect symmetry! $nextCue";
    }

    _totalLeftScore  += repLeftScore;
    _totalRightScore += repRightScore;
    _leftKneeFinal   = (_totalLeftScore  / _reps).round();
    _rightKneeFinal  = (_totalRightScore / _reps).round();
    _formScore       = ((_leftKneeFinal + _rightKneeFinal) / 2).round();

    if (_reps >= widget.prescribedReps) {
      _aiStatus = "Target reached! Finishing workout...";
      Future.delayed(const Duration(milliseconds: 500), _finishWorkout);
    }
  }

  void _finishWorkout() {
    if (_isFinished) return;
    _isFinished = true;
    _controller?.stopImageStream();

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

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21)) return null;
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
    _simulationTimer?.cancel();
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        _controller?.stopImageStream();
      } catch (e) {
        debugPrint("Error stopping image stream: $e");
      }
    }
    _controller?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 👇 Determine the color and title based on the live AI status
    Color statusColor = const Color(0xFF4353FF); // Default Blue
    String mainStatusTitle = "Positioning";

    if (_aiStatus.contains("Perfect") || _aiStatus.contains("Good")) {
      statusColor = const Color(0xFF10B981); // Green for good form
      mainStatusTitle = "Great Form!";
    } else if (_aiStatus.contains("shifting") || _aiStatus.contains("lean")) {
      statusColor = Colors.orangeAccent; // Warning orange for bad form
      mainStatusTitle = "Correct Your Posture";
    } else if (_aiStatus.contains("can't see") || _aiStatus.contains("Step back")) {
      statusColor = Colors.redAccent;
      mainStatusTitle = "Out of Frame";
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.workoutName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            if (widget.planTitle != null)
              Text("Active Plan: ${widget.planTitle}", style: const TextStyle(color: Color(0xFFFACC15), fontSize: 12, fontWeight: FontWeight.w500)),
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
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      final double cameraAspectRatio = _noCameraAvailable ? 9 / 16 : _controller!.value.aspectRatio;
                      final double portraitAspectRatio = 1 / cameraAspectRatio;

                      double scale = size.aspectRatio / portraitAspectRatio;
                      if (scale < 1.0) scale = 1.0 / scale;

                      return ClipRect(
                        child: Transform.scale(
                          scale: scale,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: portraitAspectRatio,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (_noCameraAvailable)
                                    Container(
                                      color: const Color(0xFF0F172A),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.videocam_off, color: Colors.blueGrey, size: 64),
                                          const SizedBox(height: 16),
                                          const Text("Camera Simulation Mode", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Text("Simulating pose tracking for emulators.", style: TextStyle(color: Colors.blueGrey[300], fontSize: 14)),
                                        ],
                                      ),
                                    )
                                  else
                                    CameraPreview(_controller!),
                                  if (!_noCameraAvailable && _poses != null && _imageSize != null && _rotation != null)
                                    CustomPaint(
                                      painter: PosePainter(_poses!, _imageSize!, _rotation!, _controller!.description.lensDirection),
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

                Positioned(
                  top: 100, 
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

                // 🤖 FIXED AI STATUS OVERLAY
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusColor == const Color(0xFF10B981) ? Icons.check_circle : Icons.warning_rounded,
                          color: statusColor,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          mainStatusTitle,
                          style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _aiStatus, // 👈 Now display target AI squat instructions
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _finishWorkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE50914), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              "FINISH WORKOUT",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Color(0xFF4353FF))),
    );
  }

  Widget _buildStatBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(color: Colors.blueGrey[200], fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
