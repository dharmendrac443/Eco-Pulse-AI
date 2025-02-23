import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const CustomNavBar({
    required this.currentIndex,
    required this.onItemTapped,
    super.key,
  });

  // Helper method to build navigation icons
  Widget _buildNavIcon(IconData icon, IconData iconOutline, int index, String label) {
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: currentIndex == index ? Colors.blue[100] : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(
              currentIndex == index ? icon : iconOutline,
              color: currentIndex == index ? Colors.blue[900] : Colors.grey[700],
              size: currentIndex == index ? 30 : 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: currentIndex == index ? Colors.blue[900] : Colors.grey[700],
              fontSize: 12,
              fontWeight: currentIndex == index ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon(Icons.home_rounded, Icons.home_outlined, 0, 'Home'),
            _buildNavIcon(Icons.add_circle_rounded, Icons.add_circle_outline, 1, 'Add'),
            _buildNavIcon(Icons.leaderboard_rounded, Icons.leaderboard_outlined, 2, 'Stats'),
            _buildNavIcon(Icons.task_rounded, Icons.task_outlined, 3, 'Tasks'),
          ],
        ),
      ),
    );
  }
}