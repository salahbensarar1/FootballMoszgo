import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/data/repositories/coach_management_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// The Ancient One: All your data operations in one place
/// No micro-services, no over-engineering, just practical code that works
class ReceptionistDataService {
  static const String cloudinaryUploadUrl = "https://api.cloudinary.com/v1_1/YOUR_CLOUD_NAME/image/upload";
  static const String cloudinaryUploadPreset = "YOUR_UPLOAD_PRESET";

  final CoachManagementService _coachManagementService = CoachManagementService();

  // User Profile Operations
  Future<UserProfile?> getUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(OrganizationContext.currentOrgId)
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserProfile(
          name: data['name'] ?? 'Receptionist',
          email: data['email'] ?? user.email ?? 'receptionist@example.com',
          profileImageUrl: data['picture'],
        );
      } else {
        return UserProfile(
          name: "Receptionist",
          email: user.email ?? "receptionist@example.com",
          profileImageUrl: null,
        );
      }
    } catch (e) {
      return UserProfile(
        name: "Receptionist",
        email: user?.email ?? "receptionist@example.com",
        profileImageUrl: null,
      );
    }
  }

  // Data Stream Operations
  Stream<QuerySnapshot> getStreamForTab(int currentTab) {
    final orgId = OrganizationContext.currentOrgId;
    if (orgId == null) return const Stream.empty();

    switch (currentTab) {
      case 0: // Coaches
        return FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('users')
            .where('role', isEqualTo: 'coach')
            .snapshots();
      case 1: // Players
        return FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('players')
            .snapshots();
      case 2: // Teams
        return FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('teams')
            .snapshots();
      default:
        return const Stream.empty();
    }
  }

  // Search and Filter Operations
  List<DocumentSnapshot> filterItems(List<DocumentSnapshot> items, String searchQuery, int currentTab) {
    if (searchQuery.isEmpty) return items;
    
    return items.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      switch (currentTab) {
        case 0: // Coaches
          return (data['name']?.toString() ?? '')
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
        case 1: // Players
          return (data['name']?.toString() ?? '')
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
        case 2: // Teams
          return (data['team_name']?.toString() ?? '')
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
        default:
          return false;
      }
    }).toList();
  }

  // Image Operations
  Future<File?> pickImageFromGallery() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUploadUrl));
      request.fields['upload_preset'] = cloudinaryUploadPreset;
      request.fields['folder'] = 'football_profiles';
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Player Operations
  Future<bool> updatePlayer(DocumentSnapshot player, Map<String, dynamic> updates) async {
    try {
      await player.reference.update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePlayer(DocumentSnapshot player) async {
    try {
      await player.reference.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Payment Operations
  Future<bool> togglePaymentStatus(String playerId, String year, String month, bool currentStatus) async {
    try {
      final orgId = OrganizationContext.currentOrgId;
      if (orgId == null) return false;

      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .collection('players')
          .doc(playerId)
          .collection('payments')
          .doc(year)
          .set({
        month: !currentStatus,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendPaymentReminder(String playerId) async {
    try {
      // Add your payment reminder logic here
      // This is where you'd integrate with email/SMS services
      return true;
    } catch (e) {
      return false;
    }
  }

  // Coach Operations
  Future<bool> assignCoachToPlayer(String playerId, String coachId) async {
    try {
      // Add your coach assignment logic here
      final orgId = OrganizationContext.currentOrgId;
      if (orgId == null) return false;

      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .collection('players')
          .doc(playerId)
          .update({'assignedCoach': coachId});

      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout Operation
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}

// Simple data classes - no over-engineering
class UserProfile {
  final String name;
  final String email;
  final String? profileImageUrl;

  UserProfile({
    required this.name,
    required this.email,
    this.profileImageUrl,
  });
}

class TabConfig {
  final IconData icon;
  final IconData activeIcon;
  final List<Color> gradient;
  final String name;

  TabConfig({
    required this.icon,
    required this.activeIcon,
    required this.gradient,
    required this.name,
  });
}

