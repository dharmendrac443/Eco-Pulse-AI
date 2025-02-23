import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const CustomNavBar({
    required this.currentIndex,
    required this.onItemTapped,
    super.key,
  });

  Widget _buildNavIcon(IconData icon, IconData icon_outline, int index) {
    return IconButton(
      icon: Container(
        decoration: BoxDecoration(
          color: currentIndex == index ? Colors.green[100] : Colors.transparent, // Green background when selected
          borderRadius: BorderRadius.circular(15), // Rounded edges
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            currentIndex == index ? icon: icon_outline,
            color: currentIndex == index ? Colors.green[900]: Colors.black,
            size: currentIndex == index ? 35 : 28,
          ),
        ),
      ),
      onPressed: () => onItemTapped(index),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            //top: Radius.circular(20),
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding:
          const EdgeInsets.only(top: 5, left: 20, right: 20, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavIcon(Icons.home, Icons.home_outlined, 0),
          _buildNavIcon(Icons.add_circle, Icons.add_circle_outline, 1),
          _buildNavIcon(Icons.leaderboard, Icons.leaderboard_outlined, 2),
          _buildNavIcon(Icons.task, Icons.task_outlined, 3),
        ],
      ),
    );
  }
}
