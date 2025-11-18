import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:footballtraining/services/organization_context.dart';

class ProfileSettingsDialog extends StatefulWidget {
  const ProfileSettingsDialog({super.key});

  @override
  ProfileSettingsDialogState createState() => ProfileSettingsDialogState();
}

class ProfileSettingsDialogState extends State<ProfileSettingsDialog> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  File? _imageFile;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _isLoading = true;
  bool _isUpdatingAuth = false;
  bool _showPasswordFields = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null && OrganizationContext.isInitialized) {
        final organizationId = OrganizationContext.currentOrgId;

        final userDoc = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          final data = userDoc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? user.displayName ?? '';
            _emailController.text = user.email ?? '';
            _uploadedImageUrl = data['picture'] ?? data['profileImageUrl'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _nameController.text = user.displayName ?? '';
            _emailController.text = user.email ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _uploadToCloudinary() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      String cloudName = "dycj9nypi";
      String uploadPreset = "unsigned_preset";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['quality'] = 'auto:eco';
      request.fields['fetch_format'] = 'auto';

      request.files
          .add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      var response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout. Please check your connection.');
        },
      );

      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        if (mounted) {
          final cloudinaryUrl = jsonData['secure_url'];
          print('🌤️ Cloudinary upload successful: $cloudinaryUrl');
          setState(() {
            _uploadedImageUrl = cloudinaryUrl;
            _isUploading = false;
          });
          _showSuccessSnackBar('Image uploaded successfully!');
        }
      } else {
        print('❌ Cloudinary upload failed: ${response.statusCode}');
        print('📄 Response data: $responseData');
        throw Exception(jsonData['error']['message'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showErrorSnackBar('Failed to upload image: $e');
      }
    }
  }

  // Authentication Methods
  Future<bool> _reauthenticateUser(String currentPassword) async {
    try {
      final user = _auth.currentUser;
      if (user?.email == null) return false;

      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      _showErrorSnackBar('Current password is incorrect');
      return false;
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updateEmail(newEmail);
      _showSuccessSnackBar('Email updated successfully!');
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updatePassword(newPassword);
      _showSuccessSnackBar('Password updated successfully!');
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _arePasswordFieldsValid() {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.length < 6) {
      _showErrorSnackBar('New password must be at least 6 characters');
      return false;
    }

    if (newPassword != confirmPassword) {
      _showErrorSnackBar('Passwords do not match');
      return false;
    }

    return true;
  }

  bool _validateInputs() {
    // Validate name
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Name cannot be empty');
      return false;
    }

    // Validate email
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Email cannot be empty');
      return false;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address');
      return false;
    }

    // Validate password fields if changing password
    if (_showPasswordFields) {
      if (_currentPasswordController.text.isEmpty) {
        _showErrorSnackBar('Current password is required');
        return false;
      }

      if (_newPasswordController.text.isEmpty) {
        _showErrorSnackBar('New password is required');
        return false;
      }

      if (!_arePasswordFieldsValid()) {
        return false;
      }
    }

    return true;
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isUpdatingAuth = true);

      final user = _auth.currentUser;
      if (user == null || !OrganizationContext.isInitialized) {
        throw Exception(
            'User not authenticated or organization not initialized');
      }

      // Validate inputs before processing
      if (!_validateInputs()) {
        setState(() => _isUpdatingAuth = false);
        return;
      }

      final organizationId = OrganizationContext.currentOrgId;
      bool needsReauth = false;

      // Check if email or password changes require reauthentication
      final emailChanged = _emailController.text.trim() != user.email;
      final passwordChanged = _showPasswordFields &&
          _currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty;

      needsReauth = emailChanged || passwordChanged;

      // Reauthenticate if needed
      if (needsReauth && _currentPasswordController.text.isNotEmpty) {
        final success =
            await _reauthenticateUser(_currentPasswordController.text.trim());
        if (!success) {
          setState(() => _isUpdatingAuth = false);
          return;
        }
      } else if (needsReauth) {
        _showErrorSnackBar(
            'Current password is required for email or password changes');
        setState(() => _isUpdatingAuth = false);
        return;
      }

      // Update email if changed
      if (emailChanged) {
        await _updateEmail(_emailController.text.trim());
      }

      // Update password if changed
      if (passwordChanged) {
        await _updatePassword(_newPasswordController.text.trim());
      }

      // Update Firestore document
      final updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_uploadedImageUrl != null) {
        // Save to both fields for compatibility
        updateData['profileImageUrl'] = _uploadedImageUrl!;
        updateData['picture'] = _uploadedImageUrl!;
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      // Update Firebase Auth display name
      if (_nameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      if (mounted) {
        _showSuccessSnackBar('Profile updated successfully!');
        Navigator.of(context).pop(true); // Return true to indicate update
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAuth = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isSmallScreen ? size.width * 0.95 : 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.profile,
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF27121),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Profile Image Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border:
                        Border.all(color: const Color(0xFFF27121), width: 3),
                  ),
                  child: _imageFile != null
                      ? ClipOval(
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _uploadedImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _uploadedImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Koppintson a fénykép megváltoztatásához',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Upload Button (if image selected)
              if (_imageFile != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadToCloudinary,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                        _isUploading ? 'Feltöltés...' : 'Fénykép feltöltése'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF27121),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Name Field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Név',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              // Change Password Section
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jelszó megváltoztatása',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _showPasswordFields,
                    onChanged: (value) {
                      setState(() {
                        _showPasswordFields = value;
                        if (!value) {
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                        }
                      });
                    },
                    activeColor: const Color(0xFFF27121),
                  ),
                ],
              ),

              if (_showPasswordFields) ...[
                const SizedBox(height: 16),

                // Current Password Field
                TextField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Jelenlegi jelszó',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // New Password Field
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Új jelszó',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Új jelszó megerősítése',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUpdatingAuth ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF27121),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isUpdatingAuth
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Mentés'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
