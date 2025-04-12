// import 'package:firebase_auth/firebase_auth.dart'; // Already imported below
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart'; // Usually initialized in main.dart
import 'package:flutter/material.dart';
import 'package:footballtraining/loginPage.dart'; // Your login page import
import 'package:google_fonts/google_fonts.dart';

// Import the new Detail Screen files (Create these files next)
import 'player_details_screen.dart';
import 'team_details_screen.dart';
// import 'attendance_details_screen.dart'; // Import if you create this

// PDF/Printing imports are no longer needed in AdminScreen
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

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
        setState(() { searchQuery = ""; });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Data Fetching ---
  // _getUserDetails remains the same as before...
  Future<void> _getUserDetails() async {
    final user = _auth.currentUser;
    if (user?.uid != null) {
      try {
        final doc =
        await _firestore.collection('users').doc(user!.uid).get();
        if (mounted && doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            userName = data['name'];
            email = data['email'];
          });
        } else if (mounted) {
          setState(() {
            userName = "Admin";
            email = user.email;
          });
        }
      } catch (e) {
        print("Error fetching user details: $e");
        if (mounted) {
          setState(() { userName = "Error"; email = "Error"; });
        }
      }
    } else {
      if (mounted) { setState(() { userName = "Admin"; email = "Not logged in"; });}
    }
  }

  // getStreamForCurrentTab remains the same as before...
  Stream<QuerySnapshot> getStreamForCurrentTab() {
    Query query;
    String searchField;

    switch (currentTab) {
      case 0: // Attendances
        query = _firestore.collection('attendances').orderBy('date', descending: true);
        searchField = 'playerName'; // *** Verify this field name ***
        if (searchQuery.isNotEmpty) {
          query = query
              .where(searchField, isGreaterThanOrEqualTo: searchQuery)
              .where(searchField, isLessThanOrEqualTo: '$searchQuery\uf8ff');
        }
        break;
      case 1: // Players
        query = _firestore.collection('players');
        searchField = 'name';
        if (searchQuery.isNotEmpty) {
          query = query
              .where(searchField, isGreaterThanOrEqualTo: searchQuery)
              .where(searchField, isLessThanOrEqualTo: '$searchQuery\uf8ff')
              .orderBy(searchField);
        } else {
          query = query.orderBy(searchField);
        }
        break;
      case 2: // Teams
        query = _firestore.collection('teams');
        searchField = 'team_name';
        if (searchQuery.isNotEmpty) {
          query = query
              .where(searchField, isGreaterThanOrEqualTo: searchQuery)
              .where(searchField, isLessThanOrEqualTo: '$searchQuery\uf8ff')
              .orderBy(searchField);
        } else {
          query = query.orderBy(searchField);
        }
        break;
      default:
        return const Stream.empty();
    }
    return query.snapshots();
  }

  // --- Widget Build ---
  @override
  Widget build(BuildContext context) {
    // Build method structure (AppBar, Drawer, Tabs, Search, Body) remains the same...
    var size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          title: Text(userName != null ? "Hi, $userName" : "Admin Dashboard"),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient( colors: [Color(0xFFF27121), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ),
        ),
        drawer: Drawer(
          // Drawer implementation remains the same...
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFF27121), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
            child: ListView( /* ... Drawer items ... */
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const CircleAvatar(backgroundImage: AssetImage('assets/images/admin.jpeg'), radius: 40, backgroundColor: Colors.white),
                    const SizedBox(height: 15),
                    Text(email ?? "Loading email...", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    Text(userName ?? "Admin", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],),
                ),
                ListTile( leading: const Icon(Icons.dashboard_customize, color: Colors.black87), title: const Text('Dashboard Overview'), onTap: () { Navigator.pop(context); /* Navigate or show message */ },),
                ListTile( leading: const Icon(Icons.person_add_alt_1, color: Colors.black87), title: const Text('Manage Users'), onTap: () { Navigator.pop(context); /* Navigate or show message */ },),
                const Divider(indent: 16, endIndent: 16),
                ListTile( leading: const Icon(Icons.settings, color: Colors.black87), title: const Text('Settings'), onTap: () { Navigator.pop(context); /* Navigate or show message */ },),
                ListTile( leading: const Icon(Icons.logout, color: Colors.black87), title: const Text('Logout'), onTap: () => _logout(context),),
              ],
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            // Tab Bar remains the same...
            SizedBox( width: size.width, height: size.height * 0.05, child: ListView.builder( scrollDirection: Axis.horizontal, itemCount: tabs.length, itemBuilder: (context, index) {
              return GestureDetector( onTap: () { setState(() { currentTab = index; searchQuery = ""; _searchController.clear(); }); },
                child: Padding( padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text( tabs[index], style: GoogleFonts.ubuntu( fontSize: currentTab == index ? 17 : 15, fontWeight: currentTab == index ? FontWeight.w600 : FontWeight.w400, color: currentTab == index ? const Color(0xFFF27121) : Colors.grey.shade600,),),
                ),);},),),
            const Divider(height: 1, thickness: 1),

            // Search Bar remains the same...
            Padding( padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), child: TextField( controller: _searchController, onChanged: (value) { setState(() { searchQuery = value; }); },
              decoration: InputDecoration( hintText: 'Search ${tabs[currentTab]}...', prefixIcon: const Icon(Icons.search, size: 20), border: OutlineInputBorder( borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none,), filled: true, fillColor: Colors.grey[200], contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                suffixIcon: searchQuery.isNotEmpty ? IconButton( icon: const Icon(Icons.clear, size: 20), tooltip: 'Clear Search', onPressed: () { _searchController.clear(); setState(() { searchQuery = ""; }); },) : null,),),),

            // Content Area (StreamBuilder) remains the same structure...
            Expanded(
              child: _buildContentBody(),
            ),
          ],
        ));
  }

  // --- Build Content Based on Tab ---
  Widget _buildContentBody() {
    // StreamBuilder structure remains the same...
    return StreamBuilder<QuerySnapshot>(
      stream: getStreamForCurrentTab(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator(color: Color(0xFFF27121))); }
        if (snapshot.hasError) { return Center(child: Text("Error loading ${tabs[currentTab]}. Check console & indexes.")); }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { return Center(child: Text(searchQuery.isEmpty ? "No ${tabs[currentTab]} found." : "No ${tabs[currentTab]} match your search.")); }
        var items = snapshot.data!.docs;
        return ListView.builder( itemCount: items.length, itemBuilder: (context, index) {
          var item = items[index];
          switch (currentTab) {
            case 0: return _buildAttendanceTile(item);
            case 1: return _buildPlayerTile(item);
            case 2: return _buildTeamTile(item);
            default: return const SizedBox.shrink();
          }
        },);
      },);
  }

  // --- List Tile Builders (MODIFIED) ---

  // Attendance Tile
  Widget _buildAttendanceTile(DocumentSnapshot attendanceDoc) {
    final data = attendanceDoc.data() as Map<String, dynamic>;
    String playerName = data['playerName'] ?? 'Unknown Player'; // Verify field
    Timestamp? timestamp = data['date'] as Timestamp?; // Verify field
    String dateStr = timestamp != null ? MaterialLocalizations.of(context).formatShortDate(timestamp.toDate()) : 'No Date';
    String status = data['status'] ?? 'N/A'; // Verify field
    Color statusColor = status.toLowerCase() == 'present' ? Colors.green.shade700 : (status.toLowerCase() == 'absent' ? Colors.red.shade700 : Colors.grey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(Icons.check_circle_outline, color: statusColor),
        title: Text(playerName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Date: $dateStr'),
        trailing: Text( status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),),
        // *** MODIFIED: Implement onTap for Navigation ***
        onTap: () {
          // Decide if you want a details screen for attendance
          // If yes:
          // Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceDetailsScreen(attendanceDoc: attendanceDoc)));
          // If no (like now):
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped on attendance for: $playerName on $dateStr'))
          );
          print("Attendance Doc ID: ${attendanceDoc.id}"); // Log ID for potential future use
        },
      ),
    );
  }

  // Player Tile
  Widget _buildPlayerTile(DocumentSnapshot playerDoc) {
    final data = playerDoc.data() as Map<String, dynamic>;
    String name = data['name'] ?? 'No Name';
    String position = data['position'] ?? 'N/A';
    String teamName = data['team'] ?? 'No Team';
    String? pictureUrl = data['picture'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar( radius: 25, backgroundColor: Colors.grey[300], backgroundImage: (pictureUrl != null && pictureUrl.isNotEmpty) ? NetworkImage(pictureUrl) : const AssetImage("assets/images/default_profile.jpeg") as ImageProvider, onBackgroundImageError: (_, __) {},),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Pos: $position | Team: $teamName'),
        // *** MODIFIED: Implement onTap for Navigation ***
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // Navigate to the PlayerDetailsScreen, passing the document
              builder: (context) => PlayerDetailsScreen(playerDoc: playerDoc),
            ),
          );
        },
        // *** REMOVED: Report IconButton from trailing ***
        trailing: const Icon(Icons.chevron_right, color: Colors.grey), // Indicate tappable
      ),
    );
  }

  // Team Tile
  Widget _buildTeamTile(DocumentSnapshot teamDoc) {
    final data = teamDoc.data() as Map<String, dynamic>;
    String teamName = data['team_name'] ?? 'No Team Name';
    int playerCount = data['number_of_players'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const CircleAvatar( radius: 25, backgroundColor: Colors.blueGrey, child: Icon(Icons.group, color: Colors.white),),
        title: Text(teamName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Players: $playerCount'),
        // *** MODIFIED: Implement onTap for Navigation ***
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // Navigate to the TeamDetailsScreen, passing the document
              builder: (context) => TeamDetailsScreen(teamDoc: teamDoc),
            ),
          );
        },
        // *** REMOVED: Report IconButton from trailing ***
        trailing: const Icon(Icons.chevron_right, color: Colors.grey), // Indicate tappable
      ),
    );
  }

  // --- PDF Report Generation Functions (REMOVED) ---
  // _generatePlayerReport() function is removed from here
  // _generateTeamReport() function is removed from here


  // --- Logout Function (Remains the same) ---
  void _logout(BuildContext context) async {
    // Logout logic remains the same...
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil( context, MaterialPageRoute(builder: (context) => const Loginpage()), (Route<dynamic> route) => false,);
    } catch (e) {
      print("Logout failed: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text("Logout failed: $e"), backgroundColor: Colors.red),);
    }
  }

} // End of _AdminScreenState