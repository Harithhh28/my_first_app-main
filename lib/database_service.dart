import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🧩 HELPER: Safely get the currently logged-in user's UID
  String get _uid {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User is not logged in!");
    return user.uid;
  }

  // ✅ 1. CREATE USER PROFILE (Run this right after they sign up)
  Future<void> createUserProfile(String name, String email) async {
    try {
      // This creates a document in the 'users' collection using their exact UID
      await _db.collection('users').doc(_uid).set({
        'name': name,
        'email': email,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("Profile created successfully!");
    } catch (e) {
      print("Error creating profile: $e");
    }
  }

  Future<Map<String, dynamic>?> getLatestWorkout() async {
    try {
      var snapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('workouts')
          .orderBy('date', descending: true)
          // Grab only the very top one
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null; // Return null if they haven't done any workouts yet
    } catch (e) {
      print("Error fetching latest workout: $e");
      return null;
    }
  }

  // 🔥 CALCULATE STREAK + RECOVERY % from workout history
  Future<Map<String, dynamic>> getStreakAndRecovery() async {
    try {
      // Grab the last 30 workouts (plenty to calculate a week streak)
      final snapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('workouts')
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'streak': 0, 'recovery': 0, 'weekDays': List.filled(7, false)};
      }

      final docs = snapshot.docs;

      // ── Recovery %: average form score of last 7 sessions ──────────────
      final recentDocs = docs.take(7).toList();
      double totalForm = 0;
      int formCount = 0;
      for (final doc in recentDocs) {
        final data = doc.data();
        if (data['formScore'] != null) {
          totalForm += (data['formScore'] as num).toDouble();
          formCount++;
        }
      }
      final int recoveryPct = formCount > 0 ? (totalForm / formCount).round() : 0;

      // ── Streak: count consecutive calendar days with at least 1 workout ─
      // Build a set of unique workout dates (YYYY-MM-DD strings)
      final Set<String> workoutDates = {};
      for (final doc in docs) {
        final data = doc.data();
        final ts = data['date'];
        if (ts != null && ts is Timestamp) {
          final dt = ts.toDate().toLocal();
          workoutDates.add("${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}");
        }
      }

      int streak = 0;
      DateTime cursor = DateTime.now().toLocal();
      while (true) {
        final key = "${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}";
        if (workoutDates.contains(key)) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      // ── Last 7-day bar chart indicators ─────────────────────────────────
      // Index 0 = today (leftmost), index 6 = 6 days ago (rightmost)
      final List<bool> weekDays = List.generate(7, (i) {
        final day = DateTime.now().toLocal().subtract(Duration(days: i));
        final key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
        return workoutDates.contains(key);
      });

      return {
        'streak': streak,
        'recovery': recoveryPct,
        'weekDays': weekDays,
      };
    } catch (e) {
      print("Error calculating streak/recovery: $e");
      return {'streak': 0, 'recovery': 0, 'weekDays': List.filled(7, false)};
    }
  }

  // 👇 Updated to accept painLevel!
  Future<void> saveWorkout(
    String workoutName,
    int reps,
    int formScore, {
    Map<String, int>? detailedScores,
    int painLevel = 0,
  }) async {
    try {
      await _db.collection('users').doc(_uid).collection('workouts').add({
        'workoutName': workoutName,
        'reps': reps,
        'formScore': formScore,
        'detailedScores': detailedScores ?? {}, 
        'painLevel': painLevel, // 👈 NEW: Save how much it hurt!
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving workout: $e");
    }
  }

  // 👇 ADDED: FETCH USER PROFILE
  Stream<DocumentSnapshot> getUserProfile() {
    return _db.collection('users').doc(_uid).snapshots();
  }

  // 👇 ADDED: FETCH WORKOUTS (Ordered by newest first)
  Stream<QuerySnapshot> getUserWorkouts() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('workouts')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // 👇 ADD THIS: Grabs the last 10 workouts to draw the chart
  Future<List<Map<String, dynamic>>> getWorkoutHistory() async {
    try {
      var snapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('workouts')
          // Sort oldest to newest so the chart goes left to right
          .orderBy('date', descending: false)
          .limit(10) // Show the last 10 sessions
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Error fetching history: $e");
      return [];
    }
  }

  // 🧠 THE PRESCRIPTION CALCULATION ALGORITHM
  Map<String, dynamic> calculateNextPrescription({
    required int currentReps,
    required int formScore,
    required int painLevel,
  }) {
    // If pain is excessive or form broke down heavily, trigger a regression
    if (formScore < 70 || painLevel > 6) {
      int newReps = (currentReps - 2).clamp(4, 10); // Safely drop rep volume
      return {
        "tier": "Regression",
        "nextReps": newReps,
        "level": "Light Level / Protected Range",
        "coachNote": "Form breakdown or elevated discomfort detected. Dialing back volume to protect the joint structures."
      };
    } 
    // If form is stellar and user is moving pain-free, trigger progression
    else if (formScore >= 85 && painLevel <= 3) {
      int newReps = currentReps >= 12 ? 10 : currentReps + 2;
      String targetLevel = currentReps >= 12 ? "Intermediate Level" : "Baseline Volume Up";
      return {
        "tier": "Progression",
        "nextReps": newReps,
        "level": targetLevel,
        "coachNote": "Excellent neuromuscular control. Advancing load to foster functional adaptation."
      };
    } 
    // Otherwise, maintain current path to reinforce motor patterns
    else {
      return {
        "tier": "Maintenance",
        "nextReps": currentReps,
        "level": "Current Baseline",
        "coachNote": "Safe execution. Continuing at this baseline to build structural durability."
      };
    }
  }

  // 💾 Updates previous prescription reps, calculates next, and updates database
  Future<void> updateWorkoutPrescription({
    required String workoutName,
    required int repsPerformed,
    required int formScore,
    required int painLevel,
  }) async {
    try {
      int currentPrescribedReps = repsPerformed > 0 ? repsPerformed : 10;
      
      final doc = await _db.collection('users').doc(_uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('prescriptions')) {
          final prescriptions = data['prescriptions'] as Map<String, dynamic>?;
          if (prescriptions != null && prescriptions.containsKey(workoutName)) {
            final workoutPresc = prescriptions[workoutName] as Map<String, dynamic>?;
            if (workoutPresc != null && workoutPresc.containsKey('nextReps')) {
              currentPrescribedReps = (workoutPresc['nextReps'] as num).toInt();
            }
          }
        }
      }

      final nextPresc = calculateNextPrescription(
        currentReps: currentPrescribedReps,
        formScore: formScore,
        painLevel: painLevel,
      );

      // Save the updated prescription under 'prescriptions.<workoutName>' map key
      await _db.collection('users').doc(_uid).set({
        'prescriptions': {
          workoutName: nextPresc,
        }
      }, SetOptions(merge: true));
      print("Updated prescription for $workoutName: $nextPresc");
    } catch (e) {
      print("Error updating prescription: $e");
    }
  }

  // 🔬 CLINICAL ADAPTIVE PRESCRIBING SYSTEM
  Future<void> saveAdaptiveWorkout({
    required String injuryCategory, // "Shoulder" or "Knee"
    required String workoutName,
    required int repsCompleted,
    required int formScore,
    required int painLevel,
    required int nextPrescribedReps,
    required String targetLevel,
    required String adaptationTier,
    required String coachNote,
  }) async {
    try {
      final batch = _db.batch();
      final userDoc = _db.collection('users').doc(_uid);

      // 1. Log the history record for the progress charts
      final historyRef = userDoc.collection('workouts').doc();
      batch.set(historyRef, {
        'injuryCategory': injuryCategory,
        'workoutName': workoutName,
        'reps': repsCompleted,
        'formScore': formScore,
        'painLevel': painLevel,
        'date': FieldValue.serverTimestamp(),
      });

      // 2. Update or overwrite the current prescription state for this specific exercise
      final rxRef = userDoc.collection('prescriptions').doc(workoutName);
      batch.set(rxRef, {
        'injuryCategory': injuryCategory,
        'currentLevel': targetLevel,
        'prescribedReps': nextPrescribedReps,
        'adaptationTier': adaptationTier,
        'coachNote': coachNote,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      print("Batch commit successful for adaptive workout $workoutName!");
    } catch (e) {
      print("Error executing adaptive save: $e");
    }
  }

  // 📡 Query prescriptions subcollection reactively
  Stream<QuerySnapshot> getUserPrescriptions() {
    return _db.collection('users').doc(_uid).collection('prescriptions').snapshots();
  }

  // ✅ SAVE A CUSTOM PLAN (When the user commits to it)
  Future<void> saveCustomPlan({
    required String title,
    required String description,
    required List<String> bullets,
    required String durationInfo,
    List<dynamic>? customWeeks,
  }) async {
    try {
      await _db.collection('users').doc(_uid).collection('custom_plans').add({
        'title': title,
        'description': description,
        'bullets': bullets,
        'durationInfo': durationInfo,
        'customWeeks': customWeeks ?? [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Custom plan saved successfully!");
    } catch (e) {
      print("Error saving custom plan: $e");
    }
  }

  // 📡 FETCH CUSTOM PLANS REACTIVELY
  Stream<QuerySnapshot> getCustomPlans() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('custom_plans')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ✅ SET ACTIVE PLAN
  Future<void> setActivePlan(String planTitle) async {
    try {
      await _db.collection('users').doc(_uid).set({
        'activePlanTitle': planTitle,
      }, SetOptions(merge: true));
      print("Active plan set to $planTitle");
    } catch (e) {
      print("Error setting active plan: $e");
    }
  }
}

