import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/views/coach/session_details_screen.dart';
import 'package:footballtraining/views/dashboard/dashboard_screen.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:footballtraining/views/player/player_details_screen.dart';
import 'package:footballtraining/views/team/team_details_screen.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Needed for date formatting

import 'user_management_screen.dart'; // Create this file
import 'settings_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // --- State Variables ---
  String searchQuery = "";
  int currentTab = 0; // 0: Attendances, 1: Players, 2: Teams
  List<String> tabs = ["Attendances", "Players", "Teams"];
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? userName;
  String? email;

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _getUserDetails();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && searchQuery.isNotEmpty) {
        setState(() {
          searchQuery = "";
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Data Fetching ---
  Future<void> _getUserDetails() async {
    final user = _auth.currentUser;
    if (user?.uid != null) {
      try {
        final doc = await _firestore.collection('users').doc(user!.uid).get();
        if (mounted && doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            userName = data['name'];
            email = data['email'];
          });
        } else if (mounted) {
          setState(() {
            userName = "Admin"; // Default if admin user not found in 'users'
            email = user.email; // Fallback to auth email
          });
        }
      } catch (e) {
        print("Error fetching user details: $e");
        if (mounted) {
          setState(() {
            userName = "Error";
            email = "Error";
          });
        }
      }
    } else {
      // Should not happen if screen is protected, but good practice
      if (mounted) {
        setState(() {
          userName = "Admin";
          email = "Not logged in";
        });
      }
    }
  }

  // Get stream based on tab and search query
  Stream<QuerySnapshot> getStreamForCurrentTab() {
    Query query;
    String searchField;

    switch (currentTab) {
      case 0: // Attendances - Uses training_sessions
        query = _firestore.collection('training_sessions').orderBy('start_time',
            descending: true); // Order by session start time
        searchField = 'team'; // Search sessions by team name
        if (searchQuery.isNotEmpty) {
          // Apply search filter on the 'team' field
          query = query
              .where(searchField, isGreaterThanOrEqualTo: searchQuery)
              .where(searchField, isLessThanOrEqualTo: '$searchQuery\uf8ff');
          // Requires Firestore Index: training_sessions -> team ASC, start_time DESC
        }
        break;

      case 1: // Players
        query = _firestore.collection('players');
        searchField = 'name'; // Search players by name
        if (searchQuery.isNotEmpty) {
          query = query
              .where(searchField, isGreaterThanOrEqualTo: searchQuery)
              .where(searchField, isLessThanOrEqualTo: '$searchQuery\uf8ff')
              .orderBy(searchField);
        } else {
          query = query.orderBy(searchField); // Default sort by name
        }
        break;

      case 2: // Teams
        query = _firestore.collection('teams');
        searchField = 'team_name'; // Search teams by team_name
        if (searchQuery.isNotEmpty) {
          query = query
              .where(searchField, isGreaterThanOrEqualTo: searchQuery)
              .where(searchField, isLessThanOrEqualTo: '$searchQuery\uf8ff')
              .orderBy(searchField);
        } else {
          query = query.orderBy(searchField); // Default sort by team_name
        }
        break;
      default:
        return const Stream.empty(); // Fallback
    }
    return query.snapshots();
  }

  // --- Widget Build ---
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
            // ... AppBar code ...
            ),
        drawer: Drawer(
          child: Container(
            decoration: const BoxDecoration(
              // Keep gradient if desired
              gradient: LinearGradient(
                  colors: [Color(0xFFF27121), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  // ... DrawerHeader code ...
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                            backgroundImage:
                                AssetImage('assets/images/admin.jpeg'),
                            radius: 33,
                            backgroundColor: Colors.white),
                        const SizedBox(height: 15),
                        Text(email ?? "Loading email...",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        Text(userName ?? "Admin",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w300)),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard_customize,
                      color: Colors.black87),
                  title: const Text('Dashboard Overview'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer first
                    Navigator.push(
                      // Navigate to DashboardScreen
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DashboardScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_alt_outlined,
                      color: Colors.black87), // Changed Icon
                  title: const Text('Manage Users'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      // Navigate to UserManagementScreen
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UserManagementScreen()),
                    );
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.black87),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      // Navigate to SettingsScreen
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                ListTile(
                    leading: const Icon(Icons.logout, color: Colors.black87),
                    title: const Text('Logout'),
                    onTap: () {
                      // Close the drawer *before* logging out if needed, though _logout handles navigation fully
                      // Navigator.pop(context);
                      _logout(
                          context); // Logout function already handles navigation
                    }),
              ],
            ),
          ),
        ), // End Drawer
        body: Column(
          children: <Widget>[
            // --- Tab Bar ---
            SizedBox(
              width: size.width,
              height: size.height * 0.05,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        currentTab = index;
                        searchQuery = ""; // Reset search on tab change
                        _searchController.clear(); // Clear text field
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        tabs[index],
                        style: GoogleFonts.ubuntu(
                          // Tab text styling
                          fontSize: currentTab == index ? 17 : 15,
                          fontWeight: currentTab == index
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: currentTab == index
                              ? const Color(0xFFF27121)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, thickness: 1), // Separator

            // --- Search Bar ---
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                }, // Update search query on change
                decoration: InputDecoration(
                  // Search bar styling
                  hintText:
                      'Search ${tabs[currentTab]}...', // Dynamic hint text
                  prefixIcon:
                      const Icon(Icons.search, size: 20, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true, fillColor: Colors.grey[200],
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          // Clear button
                          icon: const Icon(Icons.clear,
                              size: 20, color: Colors.grey),
                          tooltip: 'Clear Search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              searchQuery = "";
                            });
                          },
                        )
                      : null, // Show only if search query is not empty
                ),
              ),
            ),

            // --- Content Area ---
            Expanded(
              child:
                  _buildContentBody(), // Builds the list based on the current tab
            ),
          ],
        ));
  }

  // Builds the body content (the list) based on the selected tab
  Widget _buildContentBody() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          getStreamForCurrentTab(), // Gets the stream based on tab and search
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF27121)));
        }
        // Handle errors
        if (snapshot.hasError) {
          print(
              "Firestore Error (${tabs[currentTab]}): ${snapshot.error}"); // Log error
          return Center(
              child: Text(
                  "Error loading ${tabs[currentTab]}. Check console & indexes."));
        }
        // Handle no data
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(searchQuery.isEmpty
                  ? "No ${tabs[currentTab]} found."
                  : "No ${tabs[currentTab]} match your search."));
        }

        // Data is available, build the list
        var items = snapshot.data!.docs;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            var item = items[index];
            // Delegate building the list tile to specific functions
            switch (currentTab) {
              case 0:
                return _buildAttendanceTile(
                    item); // Use updated attendance tile
              case 1:
                return _buildPlayerTile(item); // Use player tile
              case 2:
                return _buildTeamTile(item); // Use team tile
              default:
                return const SizedBox.shrink(); // Empty for invalid tab index
            }
          },
        );
      },
    );
  }

  // --- List Tile Builders ---

  // Builds a list tile for an Attendance (Training Session) item
  Widget _buildAttendanceTile(DocumentSnapshot sessionDoc) {
    final data = sessionDoc.data() as Map<String, dynamic>? ?? {};

    // Extract data from the session document
    String teamName = data['team'] ?? 'N/A';
    String trainingType = data['training_type'] ?? 'N/A';
    Timestamp? startTime = data['start_time'] as Timestamp?;
    String dateStr = 'No Date';
    String timeStr = '';
    if (startTime != null) {
      try {
        // Format date and time using intl package
        dateStr = DateFormat('EEE, dd MMM yyyy').format(startTime.toDate());
        timeStr = DateFormat('HH:mm').format(startTime.toDate());
      } catch (e) {
        dateStr = 'Invalid Date';
        print("Error formatting date: $e");
      }
    }

    // Calculate attendance count from the nested 'players' array
    int attendeeCount = 0;
    int totalPlayersInSession = 0;
    final List<dynamic>? playersList = data['players'] as List<dynamic>?;
    if (playersList != null) {
      totalPlayersInSession = playersList.length;
      try {
        attendeeCount = playersList
            .where((p) => (p as Map<String, dynamic>?)?['present'] == true)
            .length;
      } catch (e) {
        print("Error reading session players array (${sessionDoc.id}): $e");
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          // Icon representing a session
          backgroundColor: Colors.indigo.shade100,
          child: const Icon(Icons.event_available,
              color: Colors.indigo, size: 22), // Changed icon
        ),
        title: Text(
          "$teamName - $trainingType", // Display team and type
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle:
            Text("$dateStr at $timeStr"), // Display formatted date and time
        trailing: Column(
          // Show attendance count
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("$attendeeCount / $totalPlayersInSession",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey.shade800)),
            Text("Present",
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600))
          ],
        ),
        onTap: () {
          // Navigate to the SessionDetailsScreen when tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionDetailsScreen(
                  sessionDoc: sessionDoc), // Pass the session document
            ),
          );
        },
      ),
    );
  }

  // Builds a list tile for a Player item
  Widget _buildPlayerTile(DocumentSnapshot playerDoc) {
    final data = playerDoc.data() as Map<String, dynamic>? ?? {}; // Safe access
    String name = data['name'] ?? 'No Name';
    String position = data['position'] ?? 'N/A';
    String teamName = data['team'] ?? 'No Team';
    String? pictureUrl = data['picture'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          // Player picture or default
          radius: 25, backgroundColor: Colors.grey[300],
          backgroundImage: (pictureUrl != null && pictureUrl.isNotEmpty)
              ? NetworkImage(pictureUrl)
              : const AssetImage("assets/images/default_profile.jpeg")
                  as ImageProvider,
          onBackgroundImageError: (_, __) {/* Optional: log error */},
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Pos: $position | Team: $teamName'),
        trailing: const Icon(Icons.chevron_right,
            color: Colors.grey), // Indicate tappable
        onTap: () {
          // Navigate to PlayerDetailsScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerDetailsScreen(
                  playerDoc: playerDoc), // Pass player document
            ),
          );
        },
      ),
    );
  }

  // Builds a list tile for a Team item
  Widget _buildTeamTile(DocumentSnapshot teamDoc) {
    final data = teamDoc.data() as Map<String, dynamic>? ?? {}; // Safe access
    String teamName = data['team_name'] ?? 'No Team Name';
    int playerCount = data['number_of_players'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const CircleAvatar(
          // Team icon
          radius: 25, backgroundColor: Colors.blueGrey,
          child: Icon(Icons.group, color: Colors.white),
        ),
        title:
            Text(teamName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Players: $playerCount'),
        trailing: const Icon(Icons.chevron_right,
            color: Colors.grey), // Indicate tappable
        onTap: () {
          // Navigate to TeamDetailsScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TeamDetailsScreen(teamDoc: teamDoc), // Pass team document
            ),
          );
        },
      ),
    );
  }

  // --- Logout Function ---
  void _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      if (!mounted)
        return; // Check if widget is still mounted before navigating
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Loginpage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Logout failed: $e");
      if (!mounted) return; // Check before showing snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Logout failed: $e"), backgroundColor: Colors.red),
      );
    }
  }
} // End of _AdminScreenState
