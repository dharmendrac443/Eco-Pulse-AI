﻿import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_pulse_ai/calculate/calculate.dart';
import 'package:eco_pulse_ai/challenges/challenges.dart';
import 'package:eco_pulse_ai/profile_page/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../leaderboard/leaderboard.dart';
import '../components/custom_app_bar.dart';
import '../components/navbar.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? _currentUserId;
  Stream<QuerySnapshot>? _monthlyDataStream;
  double totalContributions = 0;
  int treesPlanted = 0;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        setState(() {
          totalContributions = (userData['totalContributions'] ?? 0).toDouble();
          treesPlanted = (userData['treesPlanted'] ?? 0).toInt();
          _currentUserId = user.uid;
          _monthlyDataStream = FirebaseFirestore.instance
              .collection('monthly')
              .where('userId', isEqualTo: _currentUserId)
              .snapshots();
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onProfileTap() {
    setState(() {
      _currentIndex = 4;
    });
  }

  Widget _getBodyContent() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return CalculateScreen();
      case 2:
        return LeaderboardScreen();
      case 3:
        return ChallengesScreen();
      case 4:
        return ProfilePage();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Impact",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[900]),
          ),
          SizedBox(height: 20),
          _buildKeyMetrics(),
          SizedBox(height: 20),
          Text(
            "Monthly CO2 Savings",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[900]),
          ),
          SizedBox(height: 10),
          _buildScoreGraph(),
          SizedBox(height: 20),
          Text(
            "Personalized Insights",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[900]),
          ),
          SizedBox(height: 10),
          _buildInsights(),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMetricCard("CO2 Saved", "${totalContributions.toStringAsFixed(1)} kg", Icons.eco, Colors.blue),
          SizedBox(width: 16),
          _buildMetricCard("Trees Planted", "$treesPlanted", Icons.park, Colors.green),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: 150,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreGraph() {
    return StreamBuilder<QuerySnapshot>(
      stream: _monthlyDataStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No data available', style: TextStyle(color: Colors.grey));
        }

        final docs = snapshot.data!.docs;
        final chartData = _processScoreData(docs);

        return Container(
          height: 320,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: chartData['labels'].length > 0
                        ? (chartData['labels'].length - 1).toDouble()
                        : 0,
                    minY: 0,
                    maxY: chartData['maxY'],
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 2000,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(),
                      topTitles: AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 2000,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Text(
                              '${(value ~/ 1000)}k',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < chartData['labels'].length) {
                              return Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Transform.rotate(
                                  angle: -45 * (3.1416 / 180),
                                  child: Text(
                                    chartData['labels'][index],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData['spots'],
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color: Colors.blue,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _processScoreData(List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> sortedData = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      sortedData.add({
        'timestamp': DateTime(
            data['year'] ?? DateTime.now().year,
            data['month'] ?? DateTime.now().month
        ),
        'label': '${_getMonthAbbreviation(data['month'] ?? 1)} ${data['year'] ?? ''}',
        'value': (data['totalCarbonFootprint'] ?? 0).toDouble(),
      });
    }

    sortedData.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    List<FlSpot> spots = [];
    List<String> labels = [];
    double maxY = 14000;

    for (int i = 0; i < sortedData.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedData[i]['value']));
      labels.add(sortedData[i]['label']);
    }

    return {
      'spots': spots,
      'labels': labels,
      'maxY': maxY,
    };
  }

  String _getMonthAbbreviation(int month) {
    return [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][month - 1];
  }

  Widget _buildInsights() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You're doing great! Here are some tips to improve further:",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            SizedBox(height: 10),
            _buildInsightItem("Switch to LED bulbs", "Save 50kg of CO2 annually", Colors.blue),
            _buildInsightItem("Use public transport", "Reduce emissions by 20%", Colors.green),
            _buildInsightItem("Plant a tree", "Offset 21kg of CO2 per year", Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String subtitle, Color color) {
    return ListTile(
      leading: Icon(Icons.eco, color: color),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(onProfileTap: _onProfileTap),
      body: _getBodyContent(),
      bottomNavigationBar: CustomNavBar(currentIndex: _currentIndex, onItemTapped: _onItemTapped),
    );
  }
}