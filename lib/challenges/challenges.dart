import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, List<String>> challengeData = {
    'Daily': ['Walk 5,000 steps', 'Turn off lights', 'Use a reusable bottle'],
    'Weekly': ['Go car-free for 3 days', 'Compost food waste', 'Shop locally'],
    'Monthly': ['Plant a tree', 'Reduce plastic waste', 'Save electricity'],
  };

  final Map<String, List<List<DateTime>>> challengeCompletions = {
    'Daily': [[], [], []],
    'Weekly': [[], [], []],
    'Monthly': [[], [], []],
  };

  DateTime? lastCompletionDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Initialize the TabController
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose the TabController
    super.dispose();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Set<DateTime> _getAllCompletedDates() {
    Set<DateTime> allDates = {};
    challengeCompletions.forEach((category, completions) {
      completions.forEach((challenge) {
        challenge.forEach((date) {
          allDates.add(DateTime(date.year, date.month, date.day));
        });
      });
    });
    return allDates;
  }

  Widget _buildChallengeSection(String title, Color color) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 10),
            ...challengeData[title]!.asMap().entries.map((entry) {
              final index = entry.key;
              final challenge = entry.value;
              return _buildChallengeCard(challenge, color, index, title);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(String challenge, Color color, int index, String category) {
    final isCompleted = challengeCompletions[category]![index]
        .any((date) => isSameDay(date, DateTime.now()));
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Colors.white,
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.check_circle, color: color),
        title: Text(challenge, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Checkbox(
          value: isCompleted,
          onChanged: (bool? value) {
            if (value == true) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Completion'),
                  content: const Text('Have you really planted a tree?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final now = DateTime.now();
                        final normalizedDate = DateTime(now.year, now.month, now.day);

                        if (!isCompleted) {
                          setState(() {
                            challengeCompletions[category]![index].add(normalizedDate);
                          });

                          // ✅ Update Firestore: Increment `treesPlanted`
                          await _incrementTreesPlanted();
                        }
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
            } else {
              final now = DateTime.now();
              final normalizedDate = DateTime(now.year, now.month, now.day);
              setState(() {
                challengeCompletions[category]![index]
                    .removeWhere((d) => isSameDay(d, normalizedDate));
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _incrementTreesPlanted() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User not signed in.");
        return;
      }

      String userId = user.uid;
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          throw Exception("User document does not exist!");
        }

        int currentTreesPlanted = (snapshot.data() as Map<String, dynamic>)['treesPlanted'] ?? 0;
        transaction.update(userRef, {'treesPlanted': currentTreesPlanted + 1});
      });

      print("Tree count updated successfully!");
    } catch (e) {
      print("Error updating tree count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChallengeList('Daily'),
          _buildChallengeList('Weekly'),
          _buildChallengeList('Monthly'),
        ],
      ),
    );
  }

  Widget _buildChallengeList(String category) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChallengeSection(category, _getCategoryColor(category)),
          if (category == 'Weekly' || category == 'Monthly')
            ProgressCalendar(
              dates: _getAllCompletedDates(),
              isWeekly: category == 'Weekly',
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Daily':
        return Colors.green;
      case 'Weekly':
        return Colors.green;
      case 'Monthly':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class ProgressCalendar extends StatelessWidget {
  final Set<DateTime> dates;
  final bool isWeekly;

  const ProgressCalendar({Key? key, required this.dates, required this.isWeekly})
      : super(key: key);

  List<DateTime> _getDaysInWeek(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  List<DateTime> _getDaysInMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return List.generate(
        lastDay.day, (index) => DateTime(date.year, date.month, index + 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = isWeekly ? _getDaysInWeek(now) : _getDaysInMonth(now);
    final title = isWeekly
        ? 'Weekly Progress (${days.first.day}/${days.first.month} - ${days.last.day}/${days.last.month})'
        : 'Monthly Progress (${now.month}/${now.year})';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isCompleted = dates.any((d) => _isSameDay(d, day));
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green[300] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: isCompleted ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}