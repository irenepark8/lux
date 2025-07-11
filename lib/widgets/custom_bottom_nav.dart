import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final selectedColor = isDark ? Colors.white : Colors.black;
    final unselectedColor = isDark ? Colors.white.withOpacity(0.7) : Colors.grey;
    final navBarTheme = BottomNavigationBarTheme.of(context);
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.timer_outlined),
          label: 'Pomodoro',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.edit_note_outlined),
          label: 'planner',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          label: 'dict',
        ),
      ],
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      backgroundColor: bgColor,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(color: selectedColor, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(color: unselectedColor, fontWeight: FontWeight.w500),
      enableFeedback: true,
      mouseCursor: SystemMouseCursors.click,
    );
  }
}
