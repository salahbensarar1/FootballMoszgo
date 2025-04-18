import 'package:firebase_auth/firebase_auth.dart'; // To potentially get current user info
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import provider
import '../providers/theme_provider.dart'; // Import your ThemeProvider

// Placeholder for profile edit screen
// import 'edit_admin_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Placeholder Actions ---

  void _editProfile() {
    // TODO: Navigate to a screen where the admin can edit their name,
    // or initiate password change flow.
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit Profile action not implemented yet.'))
    );
    print("Current Admin UID: ${_auth.currentUser?.uid}");
  }



  void _manageNotifications() {
    // TODO: Navigate to a screen to manage notification preferences
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings not implemented yet.'))
    );
  }

  void _viewAbout() {
    // TODO: Show an About dialog or navigate to an About screen
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('About App'),
          content: const Text('Football Training App\nVersion 1.0.0\n\nDeveloped by [Your Name/Company]'), // Replace placeholder
          actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')) ],
        )
    );
  }


  @override
  Widget build(BuildContext context) {
    // Get current theme brightness (example placeholder)
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Determine switch state based on provider's state
    bool isCurrentlyDark = themeProvider.isDarkMode; // Use provider's getter


    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          flexibleSpace: Container( // Optional Gradient
            decoration: const BoxDecoration(
              gradient: LinearGradient( colors: [Color(0xFFF27121), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ),
        ),
        body: ListView( // Use ListView for setting items
          children: [
            // --- Account Section ---
            _buildSectionHeader("Account"),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Admin Profile'),
              subtitle: Text(_auth.currentUser?.email ?? 'Edit name, manage password'), // Show current admin email
              trailing: const Icon(Icons.chevron_right),
              onTap: _editProfile,
            ),

            // --- Appearance Section ---
            _buildSectionHeader("Appearance"),
            SwitchListTile(
              secondary: Icon(isCurrentlyDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
              title: const Text('Dark Mode'),
              value: isCurrentlyDark, // Use value from provider
              onChanged: (bool value) {
                // Call the provider's method to toggle the theme
                themeProvider.toggleTheme(value);
              },
              // Active color can be themed too
              activeColor: Theme.of(context).colorScheme.primary,
            ),

            // --- Notifications Section ---
            _buildSectionHeader("Notifications"),
            ListTile(
              leading: const Icon(Icons.notifications_none),
              title: const Text('Notification Preferences'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _manageNotifications,
            ),

            // --- About Section ---
            _buildSectionHeader("About"),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About App'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _viewAbout,
            ),

            // Add more settings categories and items as needed

            const SizedBox(height: 30), // Spacing at the bottom

          ],
        )
    );
  }

  // Helper to create section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.ubuntu(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary, // Use primary theme color
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}