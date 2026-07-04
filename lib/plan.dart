import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'plan_details.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  _PlanScreenState createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;

  // Track the currently active recovery plan programmatically
  String _activePlanTitle = "Shoulder Recovery";

  // 💬 GEMINI CHATBOT VARIABLES
  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _isChatInitialized = false;

  @override
  void initState() {
    super.initState();
    _initGemini();
  }

  // 🧠 INITIALIZE THE AI COACH
  void _initGemini() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite',
      systemInstruction: Content.text(
        "You are 'Rehab Ai Coach', a clinical physical therapist AI assistant. "
        "Keep your answers concise, empathetic, and medically safe. "
        "Always remind users to stop if they feel sharp pain. Do not diagnose severe conditions.",
      ),
    );
    _chat = _model.startChat();
    _isChatInitialized = true;
  }

  // 📡 THE FUNCTION THAT TALKS TO THE GEMINI API
  Future<void> _sendMessageToGemini(
    String text,
    StateSetter setModalState,
  ) async {
    if (text.trim().isEmpty || !_isChatInitialized) return;

    setModalState(() {
      _chatMessages.add({"role": "user", "text": text});
      _chatController.clear();
      _isChatLoading = true;
    });

    try {
      final response = await _chat.sendMessage(Content.text(text));
      setModalState(() {
        _chatMessages.add({
          "role": "coach",
          "text": response.text ?? "I couldn't process that.",
        });
        _isChatLoading = false;
      });
    } catch (e) {
      debugPrint("Gemini Chat Error: $e");
      setModalState(() {
        _chatMessages.add({
          "role": "coach",
          "text":
              "Connection error: $e\n\nPlease check your internet and API configuration.",
        });
        _isChatLoading = false;
      });
    }
  }

  // 💬 CHATBOT: Bottom Sheet Overlay
  void _openCoachChat() {
    if (_chatMessages.isEmpty) {
      _chatMessages.add({
        "role": "coach",
        "text":
            "Hi! I'm your Rehab Ai Coach. Do you have questions about today's protocols or need alternative exercises?",
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F19),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: const Color(0xFF4353FF).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  // Chat Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology, color: Color(0xFF4353FF)),
                            SizedBox(width: 8),
                            Text(
                              "AI Physiotherapist",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.blueGrey[400]),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Chat Timeline
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _chatMessages[index];
                        bool isUser = msg["role"] == "user";
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFF4353FF)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              msg["text"]!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Typing Indicator
                  if (_isChatLoading)
                    Padding(
                      padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Coach is typing...",
                          style: TextStyle(
                            color: Colors.blueGrey[400],
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  // Chat Input Bar
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      left: 16,
                      right: 16,
                      top: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Ask about your rehab...",
                              hintStyle: TextStyle(color: Colors.blueGrey[500]),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: const Color(0xFF4353FF),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _isChatLoading
                                ? null
                                : () => _sendMessageToGemini(
                                    _chatController.text,
                                    setModalState,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF090C14,
      ), // Dark base color matching image_354ebe.jpg
      appBar: AppBar(
        title: const Text(
          "Rehab Plans",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.greenAccent, size: 18),
                Text(
                  "PREMIUM",
                  style: TextStyle(
                    color: Colors.greenAccent[400],
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCoachChat,
        backgroundColor: const Color(0xFF4353FF),
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text(
          "Ask Coach",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // 1️⃣ SHOULDER RECOVERY
          _buildPlanCard(
            title: "Shoulder Recovery",
            description:
                "Restore range of motion and eliminate stiffness in the rotator cuff and deltoid groups.",
            bullets: [
              "AI Motion Guidance",
              "Rotator Cuff Stability",
              "Pain Level Monitoring",
            ],
            durationInfo: "6 WEEKS | 15-20 min",
            accentColor: const Color(0xFFFACC15), // Yellow Accent
            bgGradientColors: [
              const Color(0xFF131A2E),
              const Color(0xFF1E294B),
            ],
          ),
          const SizedBox(height: 16),

          // 2️⃣ KNEE RECOVERY
          _buildPlanCard(
            title: "Knee Recovery",
            description:
                "Rebuild structural alignment following ACL/MCL tweaks, meniscus tracking issues, or general wear.",
            bullets: [
              "Symmetry Tracking",
              "Dynamic Load Progression",
              "Patella Protection",
            ],
            durationInfo: "8 WEEKS | 20-30 min",
            accentColor: const Color(0xFF38BDF8), // Light Blue Accent
            bgGradientColors: [
              const Color(0xFF11222E),
              const Color(0xFF0F354A),
            ],
          ),
          const SizedBox(height: 16),

          // 3️⃣ MIX RECOVERY PLAN
          _buildPlanCard(
            title: "The Recovery Mix",
            description:
                "A comprehensive hybrid protocol shifting between kinetic upper body tracking and lower body stability.",
            bullets: [
              "Full Body Kinetic Chain",
              "Intelligent AI Switching",
              "Dual Core Tracking",
            ],
            durationInfo: "10 WEEKS | 25-35 min",
            accentColor: const Color(0xFF4ADE80), // Vibrant Green Accent
            bgGradientColors: [
              const Color(0xFF14241C),
              const Color(0xFF153D22),
            ],
          ),
          const SizedBox(
            height: 120,
          ), // Bottom breathing room for the FAB button
        ],
      ),
    );
  }

  // 🛠️ COMPONENT: The Premium Custom Plan Card
  Widget _buildPlanCard({
    required String title,
    required String description,
    required List<String> bullets,
    required String durationInfo,
    required Color accentColor,
    required List<Color> bgGradientColors,
  }) {
    bool isActive = _activePlanTitle == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activePlanTitle = title; // Mark it as active
        });

        // Navigate to the beautiful Week-by-Week Details View!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanDetailsScreen(
              title: title,
              description: description,
              bullets: bullets,
              durationInfo: durationInfo,
              accentColor: accentColor,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: bgGradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isActive
                ? accentColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row containing Title and dynamic conditional active tracking badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF042F1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF15803D),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 3.5,
                          backgroundColor: Color(0xFF22C55E),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Active",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Description Context Block
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // Bullet Checkmark items generated dynamically
            ...bullets.map(
              (bulletText) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.white, size: 16),
                    const SizedBox(width: 10),
                    Text(
                      bulletText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Time Duration Subtext line row element
            Text(
              durationInfo,
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
