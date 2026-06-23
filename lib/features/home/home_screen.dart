// lib/features/home/home_screen.dart
import 'package:adhd_list/features/dashboard/dashboard_screen.dart';
import 'package:adhd_list/features/mood_tracker/mood_tracker_screen.dart';
import 'package:adhd_list/features/task_breakdown/task_screen.dart';
import 'package:adhd_list/features/timer/timer_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    DashboardScreen(),
    TaskScreen(),
    TimerScreen(),
    MoodTrackerScreen(),
  ];

  static const _items = [
    _NavItem(icon: Icons.home_outlined,     activeIcon: Icons.home_rounded,          label: 'Home'),
    _NavItem(icon: Icons.checklist_outlined, activeIcon: Icons.checklist_rounded,     label: 'Tasks'),
    _NavItem(icon: Icons.timer_outlined,    activeIcon: Icons.timer_rounded,          label: 'Timer'),
    _NavItem(icon: Icons.mood_outlined,     activeIcon: Icons.mood_rounded,           label: 'Mood'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF2D2D44)
                  : const Color(0xFFE4E4F0),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == _selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            selected ? _items[i].activeIcon : _items[i].icon,
                            key: ValueKey(selected),
                            color: selected
                                ? cs.primary
                                : Theme.of(context)
                                    .bottomNavigationBarTheme
                                    .unselectedItemColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? cs.primary
                                : Theme.of(context)
                                    .bottomNavigationBarTheme
                                    .unselectedItemColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          width: selected ? 24 : 0,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
