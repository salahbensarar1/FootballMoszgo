import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/loginPage.dart';
import 'package:footballtraining/views/addEntryDialog.dart';
import 'package:google_fonts/google_fonts.dart';

class ReceptionistScreen extends StatefulWidget {
  const ReceptionistScreen({super.key});

  @override
  State<ReceptionistScreen> createState() => _ReceptionistScreenState();
}

class _ReceptionistScreenState extends State<ReceptionistScreen> {
  int currentTab = 0;
  String searchQuery = "";

  List<String> tabs = ["Coaches", "Players", "Teams"];

  // Function to get stream based on tab selection
  Stream<QuerySnapshot> getStreamForCurrentTab() {
    if (currentTab == 0) {
      return FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .snapshots();
    } else if (currentTab == 1) {
      return FirebaseFirestore.instance.collection('players').snapshots();
    } else {
      return FirebaseFirestore.instance.collection('teams').snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _logout(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF27121), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text("Receptionist Screen"),
      ),
      body: Column(
        children: <Widget>[
          // 🔹 Tab Selection (Coaches, Players, Teams)
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
                      searchQuery = ""; // Reset search when changing tabs
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      tabs[index],
                      style: GoogleFonts.ubuntu(
                        fontSize: currentTab == index ? 17 : 15,
                        fontWeight: currentTab == index
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: currentTab == index ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(thickness: 2, color: Color(0xFFF27121)),

          // 🔹 Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search ${tabs[currentTab]}...",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),

          // 🔹 Fetch Users from Firestore based on role
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getStreamForCurrentTab(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No ${tabs[currentTab]} found"));
                }

                // ✅ Handle Different Collections
                List<DocumentSnapshot> items = snapshot.data!.docs.where((doc) {
                  if (currentTab == 0) {
                    // Coaches
                    return doc['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase());
                  } else if (currentTab == 1) {
                    var data = doc.data() as Map<String, dynamic>?;

                    if (data == null) return false;

                    // Get the player’s name
                    String playerName =
                        data['name']?.toString().toLowerCase() ?? '';

                    // Show players whose names contain the search query (or show all if search is empty)
                    return playerName.contains(searchQuery.toLowerCase());
                  } else {
                    // Teams
                    return doc['team_name']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase());
                  }
                }).toList();

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];

                    // ✅ Different Fields for Coaches/Players vs. Teams
                    final data1 = item.data() as Map<String, dynamic>;

                    String title = '';
                    String subtitle = '';

                    if (currentTab == 0) {
                      // Coaches
                      title = data1['name'] ?? 'Unnamed Coach';
                      subtitle = data1['role_description'] ?? '';
                    } else if (currentTab == 1) {
                      // Players
                      title = data1['name'] ?? 'Unnamed Player';
                      subtitle = "Position: ${data1['position'] ?? 'Unknown'}";
                    } else {
                      // Teams
                      title = data1['team_name'] ?? 'Unnamed Team';
                      subtitle = "Players: ${data1['number_of_players'] ?? 0}";
                    }

                    // Safe retrieval for picture field
                    final data = item.data() as Map<String, dynamic>;
                    final String pictureUrl = data['picture']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: pictureUrl.isEmpty
                              ? const AssetImage(
                                  "assets/images/default_profile.jpeg")
                              : NetworkImage(pictureUrl),
                          radius: 25,
                        ),
                        title: Text(title,
                            style: GoogleFonts.ubuntu(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(subtitle,
                            style: GoogleFonts.ubuntu(
                                color: Colors.grey, fontSize: 13)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == "edit") {
                              _editUser(item); // Call edit function
                            } else if (value == "delete") {
                              _deleteUser(item);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(value: "edit", child: Text("Edit")),
                            PopupMenuItem(
                                value: "delete",
                                child: Text("Delete",
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔹 Add Button (Dynamically Changes for Coach/Player/Team)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF27121),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddEntryDialog(
                    role: currentTab == 0
                        ? "coach"
                        : currentTab == 1
                            ? "player"
                            : "team",
                  ),
                );
              },
              child: Text(
                "Add ${tabs[currentTab]}",
                style: GoogleFonts.ubuntu(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

//***********************************************************************************************************************************************************/
  void _editUser(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final nameController =
        TextEditingController(text: data['name'] ?? data['team_name']);
    final emailController = TextEditingController(text: data['email'] ?? "");
    final descriptionController = TextEditingController(
      text: data['role_description'] ?? data['team_desciption'] ?? "",
    );
    final positionController =
        TextEditingController(text: data['position'] ?? "");

    String selectedTeam = data['team'] ?? "";
    String selectedCoach = data['coach'] ?? "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Edit ${data['name'] ?? data['team_name'] ?? ''}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 👤 Name or Team Name
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: currentTab == 2 ? "Team Name" : "Name",
                ),
              ),
              if (currentTab == 0) ...[
                // Coach-specific
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: "Role Description"),
                ),
              ],
              if (currentTab == 1) ...[
                // Player-specific
                TextField(
                  controller: positionController,
                  decoration: InputDecoration(labelText: "Position"),
                ),
              ],
              if (currentTab != 2)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('teams')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();

                    List<DropdownMenuItem<String>> teamItems = snapshot
                        .data!.docs
                        .map<DropdownMenuItem<String>>((doc) {
                      final String tName = doc['team_name'];
                      return DropdownMenuItem<String>(
                        value: tName,
                        child: Text(tName),
                      );
                    }).toList();
                    return DropdownButtonFormField<String>(
                      value: selectedTeam.isNotEmpty ? selectedTeam : null,
                      items: teamItems,
                      onChanged: (val) => selectedTeam = val!,
                      decoration: InputDecoration(labelText: "Team"),
                    );
                  },
                ),
              if (currentTab == 2)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'coach')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();

                    final coachItems = snapshot.data!.docs.map((doc) {
                      final coachName = doc['name'];
                      final coachId = doc.id;
                      return DropdownMenuItem<String>(
                        value: coachId,
                        child: Text(coachName),
                      );
                    }).toList();

                    return DropdownButtonFormField<String>(
                      value: selectedCoach.isNotEmpty ? selectedCoach : null,
                      items: coachItems,
                      onChanged: (value) => selectedCoach = value!,
                      decoration: InputDecoration(labelText: "Assign Coach"),
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFF27121)),
            child: Text("Save"),
            onPressed: () async {
              try {
                if (currentTab == 0) {
                  // Coach
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(doc.id)
                      .update({
                    'name': nameController.text,
                    'email': emailController.text,
                    'role_description': descriptionController.text,
                    'team': selectedTeam,
                  });
                } else if (currentTab == 1) {
                  // Player
                  await FirebaseFirestore.instance
                      .collection('players')
                      .doc(doc.id)
                      .update({
                    'name': nameController.text,
                    'position': positionController.text,
                    'team': selectedTeam,
                  });
                } else if (currentTab == 2) {
                  // Team
                  await FirebaseFirestore.instance
                      .collection('teams')
                      .doc(doc.id)
                      .update({
                    'team_name': nameController.text,
                    'team_desciption': descriptionController.text,
                    'coach': selectedCoach,
                  });
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Successfully updated.")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to update: $e")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

//***********************************************************************************************************************************************************/
  void _deleteUser(DocumentSnapshot doc) async {
    try {
      String collection;

      if (currentTab == 0) {
        collection = 'users'; // Coach
      } else if (currentTab == 1) {
        collection = 'players'; // Player

        // 🔽 Decrement the number_of_players in the assigned team
        String teamName = doc['team'];
        final teamSnapshot = await FirebaseFirestore.instance
            .collection('teams')
            .where('team_name', isEqualTo: teamName)
            .limit(1)
            .get();

        if (teamSnapshot.docs.isNotEmpty) {
          final teamDoc = teamSnapshot.docs.first;
          final teamRef =
              FirebaseFirestore.instance.collection('teams').doc(teamDoc.id);

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(teamRef);
            final currentCount = snapshot['number_of_players'] ?? 0;
            transaction.update(teamRef,
                {'number_of_players': (currentCount - 1).clamp(0, 999)});
          });
        }
      } else {
        collection = 'teams'; // Team
      }

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(doc.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deleted successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete: $e")),
      );
    }
  }

//***********************************************************************************************************************************************************/
  // 🔹 Logout function
  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Loginpage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }
}
//***********************************************************************************************************************************************************/
