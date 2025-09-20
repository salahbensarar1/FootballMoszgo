import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:footballtraining/services/organization_context.dart';

class UserService {
  static const String cloudinaryUploadUrl = "https://api.cloudinary.com/v1_1/YOUR_CLOUD_NAME/image/upload";
  static const String cloudinaryUploadPreset = "YOUR_UPLOAD_PRESET";

  static Future<UserProfile?> getCurrentUserDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final orgId = OrganizationContext.currentOrgId;
      if (orgId == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) return null;

      final userData = userDoc.docs.first.data();
      return UserProfile(
        name: userData['name'] ?? user.displayName ?? 'User',
        email: user.email ?? '',
        profileImageUrl: userData['profileImage'] ?? user.photoURL,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<File?> pickImageFromGallery() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> uploadImageToCloudinary(File imageFile) async {
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

  static Future<bool> updateUserProfile({
    String? name,
    String? profileImageUrl,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final orgId = OrganizationContext.currentOrgId;
      
      if (user == null || orgId == null) return false;

      final userQuery = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return false;

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (profileImageUrl != null) updates['profileImage'] = profileImageUrl;

      await userQuery.docs.first.reference.update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }
}

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