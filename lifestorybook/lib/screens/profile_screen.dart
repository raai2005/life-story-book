import 'package:flutter/material.dart';
import '../utils/session_manager.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      // Clear session
      await SessionManager.clearSession();

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6C63FF), const Color(0xFF4834DF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),

              // User Name - will be populated from user data
              const Text(
                '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Email - will be populated from user data
              const Text(
                '',
                style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 40),

              // Profile Options
              _buildProfileOption(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {
                  // Navigate to edit profile
                },
              ),
              _buildProfileOption(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // Navigate to change password
                },
              ),
              _buildProfileOption(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {
                  // Navigate to notifications settings
                },
              ),
              _buildProfileOption(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
                onTap: () {
                  // Navigate to language settings
                },
              ),
              _buildProfileOption(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  // Navigate to help
                },
              ),
              _buildProfileOption(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  // Navigate to about
                },
              ),
              const SizedBox(height: 20),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _handleLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Version Info
              const Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF6C63FF), size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
