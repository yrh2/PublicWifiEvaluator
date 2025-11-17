import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/common_bottom_navigation.dart';

class HelpAboutScreen extends StatelessWidget {
  const HelpAboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode
              ? Colors.grey[900]
              : Colors.white,
          appBar: AppBar(
            backgroundColor: themeProvider.isDarkMode
                ? Colors.grey[900]
                : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Help/About',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Docs and Support header
                Text(
                  'Docs and Support',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // Quick Tips Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[800]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[700]!
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Avoid logging into sensitive accounts (e.g., banking, work emails) when using public Wi-Fi.\n'
                        '2. Disable automatic Wi-Fi connections to prevent connecting to unknown or rogue networks.\n'
                        '3. Prefer HTTPS websites and use VPN when accessing sensitive data.\n'
                        '4. Always check your Wi-Fi security score using this app before browsing.',
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // User Manual (Interactive)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[800]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[700]!
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Manual (Quick Guide)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Step 1: Login / Sign Up
                      ExpansionTile(
                        leading: const Icon(Icons.login),
                        title: Text(
                          '1. Login or Sign Up',
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.grey[200]
                                : Colors.grey[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        children: [
                          ListTile(
                            title: Text(
                              'Start by logging in or creating a new account. After successful sign-up, you’ll be redirected to the Home screen automatically.',
                              style: TextStyle(
                                fontSize: 13,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Step 2: Home Screen
                      ExpansionTile(
                        leading: const Icon(Icons.home),
                        title: Text(
                          '2. Home Screen',
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.grey[200]
                                : Colors.grey[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        children: [
                          ListTile(
                            title: Text(
                              'View your connected Wi-Fi SSID, signal strength, and security type. Tap “Scan” to check your network safety.',
                              style: TextStyle(
                                fontSize: 13,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Step 3: Scan Results
                      ExpansionTile(
                        leading: const Icon(Icons.security),
                        title: Text(
                          '3. Scan Results',
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.grey[200]
                                : Colors.grey[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        children: [
                          ListTile(
                            title: Text(
                              'After scanning, the app will display threat score will be automatically to Scan Results page where it displays detected threats such as ARP spoofing, DNS spoofing, open ports, or rogue access points. Each affects your Wi-Fi safety score.',
                              style: TextStyle(
                                fontSize: 13,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Step 4: Recommendations
                      ExpansionTile(
                        leading: const Icon(Icons.lightbulb),
                        title: Text(
                          '4. Recommendations',
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.grey[200]
                                : Colors.grey[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        children: [
                          ListTile(
                            title: Text(
                              'Check personalized Wi-Fi safety recommendations. Based on the threat score, you’ll see if the Wi-Fi is safe or unsafe to use.',
                              style: TextStyle(
                                fontSize: 13,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Step 5: History & Profile
                      ExpansionTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          '5. History and Profile',
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.grey[200]
                                : Colors.grey[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        children: [
                          ListTile(
                            title: Text(
                              'Go to Scan History to review past scans. In Profile, update your name, password, or switch between Light and Dark themes.',
                              style: TextStyle(
                                fontSize: 13,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Step 6: Help/About
                      ExpansionTile(
                        leading: const Icon(Icons.help_outline),
                        title: Text(
                          '6. Help/About',
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.grey[200]
                                : Colors.grey[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        children: [
                          ListTile(
                            title: Text(
                              'Return to this page anytime for quick tips, app information, or developer contact.',
                              style: TextStyle(
                                fontSize: 13,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // About Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[800]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[700]!
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Version: 1.0.0\n'
                        'Developer: Syahirah\n'
                        'Contact: dev@gmail.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),

          bottomNavigationBar: const CommonBottomNavigation(currentIndex: 4),
        );
      },
    );
  }
}
