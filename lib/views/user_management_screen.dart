import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current admin UID
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Placeholder for Edit User Screen/Dialog (if needed later)
// import 'edit_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // To filter out current admin

  // State for potential search/filter later
  String searchQuery = "";
  String? selectedRoleFilter; // e.g., 'coach', 'admin'

  // Function to build the stream based on filters
  Stream<QuerySnapshot> _getUsersStream() {
    Query query = _firestore.collection('users').orderBy('name'); // Default order

    // --- Filtering Logic ---
    // Filter out the currently logged-in admin to prevent self-modification here
    final String? currentAdminUid = _auth.currentUser?.uid;
    if (currentAdminUid != null) {
      // Note: Firestore doesn't support direct '!=' query on document ID easily combined with others.
      // We'll filter client-side for simplicity here, but for large user bases,
      // a backend solution or structuring data differently might be better.
    }

    // Filter by selected role if one is chosen
    if (selectedRoleFilter != null && selectedRoleFilter!.isNotEmpty) {
      query = query.where('role', isEqualTo: selectedRoleFilter);
      // Requires Index: users -> role ASC, name ASC
    }

    // Apply search query (simple prefix search on name)
    if (searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff');
      // May require composite index depending on other filters, e.g.,
      // users -> role ASC, name ASC
      // users -> name ASC
    }

    return query.snapshots();
  }


  // --- Action Placeholders ---
  void _editUser(DocumentSnapshot userDoc) {
    // TODO: Implement navigation to an Edit User screen or show an Edit Dialog
    // Pass userDoc.id or userDoc itself
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Edit action for ${userDoc['name']} not implemented yet.'))
    );
    print("Edit user ID: ${userDoc.id}");
  }

  void _deleteUser(DocumentSnapshot userDoc) async {
    final userName = userDoc['name'] ?? 'this user';
    final userRole = userDoc['role'] ?? 'user';

    // --- Confirmation Dialog ---
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete $userName ($userRole)? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // TODO: Implement actual Firestore delete logic
      // Consider cascading effects (e.g., unassigning coach from teams)
      print("Attempting to delete user ID: ${userDoc.id}");
      try {
        // --- Example Firestore Delete (Implement with caution!) ---
        // await _firestore.collection('users').doc(userDoc.id).delete();
        // --- Also handle unassigning coach if applicable ---
        // if (userRole == 'coach') {
        //    WriteBatch batch = _firestore.batch();
        //    final teamsManaged = await _firestore.collection('teams').where('coach', isEqualTo: userDoc.id).get();
        //    for (var teamDoc in teamsManaged.docs) {
        //       batch.update(teamDoc.reference, {'coach': null}); // or ''
        //    }
        //    await batch.commit();
        // }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deletion for $userName NOT implemented yet (check TODO).'), backgroundColor: Colors.orange)
        );
      } catch (e) {
        print("Error during user deletion placeholder: $e");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting $userName: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _addUser() {
    // TODO: Implement navigation to Add User screen or show Add User Dialog
    // Should allow setting name, email, password (or invite), role
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add User action not implemented yet.'))
    );
  }


  @override
  Widget build(BuildContext context) {
    final String? currentAdminUid = _auth.currentUser?.uid; // Get current admin UID

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        flexibleSpace: Container( // Optional Gradient
          decoration: const BoxDecoration(
            gradient: LinearGradient( colors: [Color(0xFFF27121), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
        ),
        // Optional: Add Filter button here later
        // actions: [ IconButton(icon: Icon(Icons.filter_list), onPressed: _showFilterDialog) ],
      ),
      body: Column(
        children: [
          // TODO: Add Search Bar and Filter Dropdown later if needed
          // Padding( ... TextField(onChanged: (val) => setState(() => searchQuery = val)) ... ),
          // Padding( ... DropdownButtonFormField<String>(...) ...),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("Error loading users: ${snapshot.error}");
                  return const Center(child: Text("Error loading users."));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found."));
                }

                // Filter out the current admin client-side
                final users = snapshot.data!.docs.where((doc) => doc.id != currentAdminUid).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("No other users found."));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final data = userDoc.data() as Map<String, dynamic>? ?? {};

                    final name = data['name'] ?? 'N/A';
                    final email = data['email'] ?? 'No Email';
                    final role = data['role'] ?? 'No Role';
                    final pictureUrl = data['picture'] as String?; // Assuming picture field exists

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: CircleAvatar( // User picture or default
                          radius: 22, backgroundColor: Colors.grey[300],
                          backgroundImage: (pictureUrl != null && pictureUrl.isNotEmpty)
                              ? NetworkImage(pictureUrl)
                              : const AssetImage("assets/images/default_profile.jpeg") as ImageProvider, // Use default asset
                          onBackgroundImageError: (_, __) {},
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text("$email\nRole: ${role.toUpperCase()}", style: TextStyle(color: Colors.grey.shade600)),
                        isThreeLine: true, // Allow space for role line
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          tooltip: 'User Actions',
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editUser(userDoc);
                            } else if (value == 'delete') {
                              _deleteUser(userDoc);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit Role')),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Delete User', style: TextStyle(color: Colors.red))),
                            ),
                          ],
                        ),
                        onTap: () => _editUser(userDoc), // Allow tapping list tile to edit as well
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser, // Call placeholder function
        tooltip: 'Add User',
        backgroundColor: const Color(0xFFF27121), // Theme color
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}