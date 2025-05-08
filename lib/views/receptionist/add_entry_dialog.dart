import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AddEntryDialog extends StatefulWidget {
  final String role; // "coach", "player", or "team"

  const AddEntryDialog({Key? key, required this.role}) : super(key: key);

  @override
  _AddEntryDialogState createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
  final _formKey = GlobalKey<FormState>();

  // Common fields (used by multiple roles)
  String name = "";

  // --- COACH fields ---
  String email = "";
  String password = "";
  String roleDescription = "";
  File? _imageFile;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  String? selectedTeamForCoach; // For coaches only

  // --- PLAYER fields ---
  DateTime? birthDate;
  String position = "";
  String? selectedTeamForPlayer; // For players only

  // --- TEAM fields ---
  String teamName = "";
  String teamDesciption = "";
  String? selectedCoachForTeam;
  // Removed numberOfPlayers field since this is managed automatically

  // --------------------------------------------
  //                FIRESTORE
  // --------------------------------------------

  /// Stream of teams to populate dropdown for coaches/players
  Stream<QuerySnapshot> getTeamsStream() {
    return FirebaseFirestore.instance.collection('teams').snapshots();
  }

  // --------------------------------------------
  //            IMAGE PICK & UPLOAD
  // --------------------------------------------
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadToCloudinary() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    String cloudName = "dycj9nypi"; // your Cloudinary cloud name
    String uploadPreset = "unsigned_preset"; // your Cloudinary preset

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
    );

    request.fields['upload_preset'] = uploadPreset;
    request.files
        .add(await http.MultipartFile.fromPath('file', _imageFile!.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonData = json.decode(responseData);

    if (response.statusCode == 200) {
      setState(() {
        _uploadedImageUrl = jsonData['secure_url'];
        _isUploading = false;
      });
    } else {
      print("Upload failed: ${jsonData['error']['message']}");
      setState(() {
        _isUploading = false;
      });
    }
  }

  // --------------------------------------------
  //            ADD DATA FUNCTIONS
  // --------------------------------------------

  /// Creates a Firebase Auth user and adds coach details to Firestore.
  Future<void> _addCoach() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload an image for the Coach.")),
      );
      return;
    }

    try {
      // ✅ Step 1: Create coach in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String coachUID = userCredential.user!.uid;

      // ✅ Step 2: Save coach details in `users` collection
      await FirebaseFirestore.instance.collection('users').doc(coachUID).set({
        "name": name,
        "email": email,
        "role": "coach",
        "role_description": roleDescription,
        "team": selectedTeamForCoach ?? "Unassigned",
        "picture": _uploadedImageUrl ?? "https://example.com/default.jpg",
      });

      // ✅ Step 3: Update the selected team with coach UID
      if (selectedTeamForCoach != null) {
        final teamSnapshot = await FirebaseFirestore.instance
            .collection('teams')
            .where('team_name', isEqualTo: selectedTeamForCoach)
            .limit(1)
            .get();

        if (teamSnapshot.docs.isNotEmpty) {
          final teamDocId = teamSnapshot.docs.first.id;
          await FirebaseFirestore.instance
              .collection('teams')
              .doc(teamDocId)
              .update({
            'coach': coachUID,
          });
        }
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding coach: $e")),
      );
    }
  }

  /// Adds a new Player document to the `players` collection and
  /// increments the team's player count automatically.
  Future<void> _addPlayer() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (selectedTeamForPlayer == null || selectedTeamForPlayer!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a team for the player.")),
      );
      return;
    }

    try {
      // 🔎 Find the team document by its name
      final teamSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .where('team_name', isEqualTo: selectedTeamForPlayer)
          .limit(1)
          .get();

      if (teamSnapshot.docs.isEmpty) {
        // Team doesn't exist: create it and set count = 1
        await FirebaseFirestore.instance.collection('teams').add({
          'team_name': selectedTeamForPlayer,
          'number_of_players': 1,
        });
      } else {
        // Team exists: increment player count
        final teamDoc = teamSnapshot.docs.first;
        final teamRef =
            FirebaseFirestore.instance.collection('teams').doc(teamDoc.id);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(teamRef);
          final oldCount = snapshot.get('number_of_players') ?? 0;
          transaction.update(teamRef, {'number_of_players': oldCount + 1});
        });
      }

      // 👤 Add the player to the players collection
      await FirebaseFirestore.instance.collection('players').add({
        "name": name,
        "birth_date": birthDate != null ? Timestamp.fromDate(birthDate!) : null,
        "position": position,
        "team": selectedTeamForPlayer,
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding player: $e")),
      );
    }
  }

  /// Adds a new Team document to the `teams` collection.
  Future<void> _addTeam() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      await FirebaseFirestore.instance.collection('teams').add({
        "team_name": teamName,
        "team_desciption": teamDesciption,
        "number_of_players": 0,
        "coach": selectedCoachForTeam ?? "", // Coach UID
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding team: $e")),
      );
    }
  }

  // --------------------------------------------
  //         BUILD & ROLE-BASED UI
  // --------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text("Add ${widget.role.capitalize()}"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildFormFieldsForRole(),
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text("Add"),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFF27121)),
          onPressed: _onAddPressed,
        ),
      ],
    );
  }

  /// Returns a list of form fields depending on the role.
  List<Widget> _buildFormFieldsForRole() {
    if (widget.role == 'coach') {
      return _buildCoachFields();
    } else if (widget.role == 'player') {
      return _buildPlayerFields();
    } else {
      // 'team'
      return _buildTeamFields();
    }
  }

  /// Role = Coach => Name, Email, Password, Role Desc, Team, Image
  List<Widget> _buildCoachFields() {
    return [
      TextFormField(
        decoration: InputDecoration(labelText: "Name"),
        validator: (value) => value!.isEmpty ? "Enter a name" : null,
        onSaved: (value) => name = value!.trim(),
      ),
      TextFormField(
        decoration: InputDecoration(labelText: "Email"),
        validator: (value) => value!.isEmpty ? "Enter an email" : null,
        onSaved: (value) => email = value!.trim(),
      ),
      TextFormField(
        decoration: InputDecoration(labelText: "Password"),
        obscureText: true,
        validator: (value) =>
            value!.length < 6 ? "Password must be at least 6 characters" : null,
        onSaved: (value) => password = value!,
      ),
      TextFormField(
        decoration: InputDecoration(labelText: "Role Description (Optional)"),
        onSaved: (value) => roleDescription = value ?? "",
      ),
      const SizedBox(height: 10),

      // Team Dropdown for coach assignment
      StreamBuilder<QuerySnapshot>(
        stream: getTeamsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          List<DropdownMenuItem<String>> teamItems =
              snapshot.data!.docs.map<DropdownMenuItem<String>>((doc) {
            final tName = doc['team_name'] as String;
            return DropdownMenuItem<String>(
              value: tName,
              child: Text(tName),
            );
          }).toList();

          return DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: "Assign to Team"),
            items: teamItems,
            onChanged: (value) {
              selectedTeamForCoach = value;
            },
          );
        },
      ),

      const SizedBox(height: 10),

      // Image Picker for coach profile picture
      GestureDetector(
        onTap: _pickImage,
        child: CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[300],
          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
          child: _imageFile == null
              ? Icon(Icons.camera_alt, size: 30, color: Colors.white)
              : null,
        ),
      ),

      const SizedBox(height: 10),

      // Upload Button for image upload
      ElevatedButton(
        onPressed: _uploadToCloudinary,
        child: _isUploading
            ? CircularProgressIndicator(color: Colors.white)
            : Text("Upload Image"),
      ),
    ];
  }

  /// Role = Player => Name, Birth Date, Position, Team
  List<Widget> _buildPlayerFields() {
    return [
      TextFormField(
        decoration: InputDecoration(labelText: "Player Name"),
        validator: (value) => value!.isEmpty ? "Enter player name" : null,
        onSaved: (value) => name = value!.trim(),
      ),
      const SizedBox(height: 10),

      // Birth Date Picker
      GestureDetector(
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            setState(() {
              birthDate = pickedDate;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: 'Birth Date'),
          child: Text(
            birthDate == null
                ? 'Tap to select date'
                : DateFormat('yyyy-MM-dd').format(birthDate!),
          ),
        ),
      ),
      const SizedBox(height: 10),

      // Position field
      TextFormField(
        decoration: InputDecoration(labelText: "Position"),
        validator: (value) => value!.isEmpty ? "Enter position" : null,
        onSaved: (value) => position = value!.trim(),
      ),
      const SizedBox(height: 10),

      // Team Dropdown for players
      StreamBuilder<QuerySnapshot>(
        stream: getTeamsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          List<DropdownMenuItem<String>> teamItems =
              snapshot.data!.docs.map<DropdownMenuItem<String>>((doc) {
            final tName = doc['team_name'] as String;
            return DropdownMenuItem<String>(
              value: tName,
              child: Text(tName),
            );
          }).toList();

          return DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: "Select Team"),
            items: teamItems,
            onChanged: (value) {
              selectedTeamForPlayer = value;
            },
          );
        },
      ),
    ];
  }

  /// Role = Team => Only Team Name (number_of_players is managed automatically)
  List<Widget> _buildTeamFields() {
    return [
      TextFormField(
        decoration: InputDecoration(labelText: "Team Name"),
        validator: (value) => value!.isEmpty ? "Enter team name" : null,
        onSaved: (value) => teamName = value!.trim(),
      ),
      TextFormField(
        decoration: InputDecoration(labelText: "Team Description"),
        validator: (value) => value!.isEmpty ? "Enter team description" : null,
        onSaved: (value) => teamDesciption = value!.trim(),
      ),
      const SizedBox(height: 10),

      // Coach Dropdown
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'coach')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          List<DropdownMenuItem<String>> coachItems =
              snapshot.data!.docs.map<DropdownMenuItem<String>>((doc) {
            final coachName = doc['name'];
            final coachId = doc.id;
            return DropdownMenuItem<String>(
              value: coachId,
              child: Text(coachName),
            );
          }).toList();

          return DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: "Assign Coach"),
            items: coachItems,
            onChanged: (value) {
              selectedCoachForTeam = value;
            },
          );
        },
      ),
    ];
  }

  /// Single onPressed callback that checks which role is being added and calls the appropriate function.
  void _onAddPressed() {
    if (widget.role == 'coach') {
      _addCoach();
    } else if (widget.role == 'player') {
      _addPlayer();
    } else {
      _addTeam();
    }
  }
}

// Simple string extension for capitalizing
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
