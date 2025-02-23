import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_pulse_ai/leaderboard/components/userCard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> leaderboard = [];
  final ScrollController _scrollController = ScrollController();
  bool _isUserVisible = false;
  int _displayedUsers = 5;
  String? _currentUserId;
  Map<String, dynamic>? _currentUserData;
  static const double _itemHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _scrollController.addListener(_checkUserVisibility);
  }

  Future<void> _fetchCurrentUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      await _fetchLeaderboard();
    }
  }

  Future<void> _fetchLeaderboard() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalContributions', descending: true)
          .get();

      List<Map<String, dynamic>> users = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'name': data['name'] ?? 'Unknown',
          'countrycode': data['countryCode'] ?? 'unknown',
          'score': data['totalContributions'] ?? 0,
          'uid': doc.id,
          'rank': doc.id,
        };
      }).toList();

      for (int i = 0; i < users.length; i++) {
        users[i]['rank'] = i + 1;
      }

      setState(() {
        leaderboard = users;
        try {
          _currentUserData = users.firstWhere(
            (user) => user['uid'] == _currentUserId
          );
        } catch (e) {
          _currentUserData = null;
        }
      });
    } catch (error) {
      print("Error fetching leaderboard: $error");
    }
  }

    void _loadMoreUsers() {
    setState(() {
      _displayedUsers = (_displayedUsers + 10).clamp(10, leaderboard.length);
      if (_currentUserData != null && !_isUserVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  void _reduceUsers() {
    setState(() {
      _displayedUsers = (_displayedUsers - 10).clamp(10, leaderboard.length);
    });
  }

  void _checkUserVisibility() {
    if (_currentUserData == null) return;
    
    final userIndex = leaderboard.indexOf(_currentUserData!);
    if (userIndex == -1) return;

    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final itemPosition = userIndex * _itemHeight;

    setState(() {
      _isUserVisible = itemPosition >= scrollOffset &&
          itemPosition <= scrollOffset + viewportHeight - _itemHeight;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showViewMore = leaderboard.length > _displayedUsers;
    final bool showViewLess = _displayedUsers > 10;
    final bool currentUserInList = _currentUserData != null &&
        leaderboard.indexOf(_currentUserData!) < _displayedUsers;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Text('Your Current Rank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
          
          // Current User Card at Top
          if (_currentUserData != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: userCard(_currentUserData!, true),
            ),

          // Table Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Table(
              columnWidths: {
                0: FixedColumnWidth(50),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(50),
              },
              children: [
                TableRow(
                  children: [
                    Text('Rank', style: _headerTextStyle),
                    Text('Name', style: _headerTextStyle),
                    Text('Score', style: _headerTextStyle),
                  ],
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: leaderboard.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _displayedUsers + 
                        (showViewMore || showViewLess ? 1 : 0) +
                        (!currentUserInList && _currentUserData != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (!currentUserInList && 
                          _currentUserData != null && 
                          index == _displayedUsers) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: userCard(_currentUserData!, true),
                        );
                      }
                      
                      if (index == _displayedUsers + 
                          (!currentUserInList && _currentUserData != null ? 1 : 0)) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (showViewMore)
                                _buildActionButton(
                                  'View More',
                                  showViewMore ? _loadMoreUsers : null,
                                ),
                              if (showViewLess)
                                const SizedBox(width: 20),
                              if (showViewLess)
                                _buildActionButton(
                                  'View Less',
                                  showViewLess ? _reduceUsers : null,
                                ),
                            ],
                          ),
                        );
                      }
                      
                      if (index >= _displayedUsers) return Container();
                      final user = leaderboard[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: userCard(user, user['uid'] == _currentUserId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback? onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.green,
        side: const BorderSide(color: Colors.grey, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

const _headerTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.black,
  fontWeight: FontWeight.bold,
);