import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onProfileTap;

  const CustomAppBar({super.key, required this.onProfileTap});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  void initState() {
    super.initState();
    _updateStreak();
  }

Future<void> _updateStreak() async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userDoc = FirebaseFirestore.instance.collection('streak').doc(user.uid);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(userDoc);
    if (!snapshot.exists) return;

    Map<String, dynamic> data = snapshot.data()!;
    int currentStreak = data['currentStreak'] ?? 0;
    int maxStreak = data['maxStreak'] ?? 0;
    DateTime lastLogin = (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime(2000);

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);

    if (lastLoginDate.isBefore(today.subtract(const Duration(days: 1)))) {
      // Missed a day, reset streak to 0
      currentStreak = 0;
    }

    // Update max streak only if current streak is higher
    maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;

    transaction.update(userDoc, {
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      // 'lastLogin': Timestamp.fromDate(now),
    });
  });
}


  Stream<Map<String, int>> _streaksStream() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value({'currentStreak': 0, 'maxStreak': 0});
    }

    return FirebaseFirestore.instance
        .collection('streak')
        .doc(user.uid) // Directly accessing user's streak document
        .snapshots()
        .map((doc) {
      if (!doc.exists) return {'currentStreak': 0, 'maxStreak': 0};

      Map<String, dynamic> data = doc.data()!;
      return {
        'currentStreak': (data['currentStreak'] as num?)?.toInt() ?? 0,
        'maxStreak': (data['maxStreak'] as num?)?.toInt() ?? 0,
      };
    });
  }

  void _showStreakPopup(int currentStreak, int maxStreak) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🔥 Streak Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("🔥 Current Streak: $currentStreak days",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("🏆 Max Streak: $maxStreak days",
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // Remove the back button
      backgroundColor: Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.eco, size: 40, color: Colors.green),
          Row(
            children: [
              StreamBuilder<Map<String, int>>(
                stream: _streaksStream(),
                builder: (context, snapshot) {
                  int currentStreak = snapshot.data?['currentStreak'] ?? 0;
                  int maxStreak = snapshot.data?['maxStreak'] ?? 0;

                  return GestureDetector(
                    onTap: () => _showStreakPopup(currentStreak, maxStreak),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 30, color: Colors.red),
                        const SizedBox(width: 5),
                        Text(
                          '$currentStreak',
                          style: const TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: const Icon(Icons.person_outline, size: 30, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
