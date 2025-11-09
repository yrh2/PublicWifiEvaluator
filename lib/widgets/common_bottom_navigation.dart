import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/home_screen.dart';
import '../screens/scan_history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recommendations_screen.dart';

class CommonBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const CommonBottomNavigation({Key? key, required this.currentIndex})
    : super(key: key);

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0: // Home - always allow navigation to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1: // WiFi (same as home for now)
        if (index == currentIndex)
          return; // Don't navigate if already on same page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 2: // Security/Recommendations
        if (index == currentIndex)
          return; // Don't navigate if already on same page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const RecommendationsScreen(),
          ),
        );
        break;
      case 3: // History
        if (index == currentIndex)
          return; // Don't navigate if already on same page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ScanHistoryScreen()),
        );
        break;
      case 4: // Profile
        if (index == currentIndex)
          return; // Don't navigate if already on same page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey.shade200,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => _navigateToPage(context, 0),
                icon: Icon(
                  Icons.home,
                  color: currentIndex == 0
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.grey[400] : Colors.grey),
                ),
              ),
              IconButton(
                onPressed: () => _navigateToPage(context, 1),
                icon: Icon(
                  Icons.wifi,
                  color: currentIndex == 1
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.grey[400] : Colors.grey),
                ),
              ),
              IconButton(
                onPressed: () => _navigateToPage(context, 2),
                icon: Icon(
                  Icons.security,
                  color: currentIndex == 2
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.grey[400] : Colors.grey),
                ),
              ),
              IconButton(
                onPressed: () => _navigateToPage(context, 3),
                icon: Icon(
                  Icons.history,
                  color: currentIndex == 3
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.grey[400] : Colors.grey),
                ),
              ),
              IconButton(
                onPressed: () => _navigateToPage(context, 4),
                icon: Icon(
                  Icons.person,
                  color: currentIndex == 4
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.grey[400] : Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
