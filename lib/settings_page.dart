import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'insights_page.dart';
import 'chat_history_page.dart';
import 'profile_information_page.dart';
import 'change_password_page.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF002D62)),
        title: Text(
          'Account Settings',
          style: GoogleFonts.poppins(
            color: Color(0xFF002D62),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Update your settings like notifications, payments, profile edit etc.',
              style: GoogleFonts.poppins(
                color: Color(0xFF002D62).withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _settingsTile(
                    context,
                    icon: Icons.person_outline,
                    title: 'Profile Information',
                    subtitle: 'Change your account information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileInformationPage()),
                      );
                    },
                  ),
                  _divider(),
                  _settingsTile(
                    context,
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Change your password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                      );
                    },
                  ),
                  _divider(),
                  _settingsTile(
                    context,
                    icon: Icons.insights,
                    title: 'Insights',
                    subtitle: 'View your engagement & mental health dashboard',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => InsightsPage()),
                      );
                    },
                  ),
                  _divider(),
                  _settingsTile(
                    context,
                    icon: Icons.history,
                    title: 'Chat History',
                    subtitle: 'View and manage your chat sessions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatHistoryPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF002D62)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Color(0xFF002D62),
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: Color(0xFF002D62).withOpacity(0.7),
          fontSize: 13,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Color(0xFF002D62)),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 2),
    );
  }

  Widget _divider() {
    return Divider(height: 0, thickness: 1, color: Colors.grey[200]);
  }
}
