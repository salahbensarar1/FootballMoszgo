import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEntryDialog extends StatefulWidget {
  final String role; // "coach", "player", or "team"

  const AddEntryDialog({Key? key, required this.role}) : super(key: key);

  @override
  _AddEntryDialogState createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _submitController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Focus nodes for better UX
  final List<FocusNode> _focusNodes = [];

  // Common fields
  String name = "";

  // Coach fields
  String email = "";
  String password = "";
  String roleDescription = "";
  File? _imageFile;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  String? selectedTeamForCoach;

  // Player fields
  DateTime? birthDate;
  String position = "";
  String? selectedTeamForPlayer;

  // Team fields
  String teamName = "";
  String teamDescription = "";
  String? selectedCoachForTeam;

  // UI state
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  // Color schemes based on role
  Map<String, Map<String, dynamic>> get roleConfig => {
        'coach': {
          'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
          'icon': Icons.sports_rounded,
          'lightColor': Color(0xFF667eea).withOpacity(0.1),
        },
        'player': {
          'gradient': [Color(0xFF10B981), Color(0xFF059669)],
          'icon': Icons.person_rounded,
          'lightColor': Color(0xFF10B981).withOpacity(0.1),
        },
        'team': {
          'gradient': [Color(0xFFF59E0B), Color(0xFFD97706)],
          'icon': Icons.groups_rounded,
          'lightColor': Color(0xFFF59E0B).withOpacity(0.1),
        },
      };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupFocusNodes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _submitController.dispose();
    _scrollController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _submitController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  void _setupFocusNodes() {
    // Create focus nodes based on role
    int nodeCount = widget.role == 'coach'
        ? 4
        : widget.role == 'player'
            ? 3
            : 2;
    for (int i = 0; i < nodeCount; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  Color get primaryColor => roleConfig[widget.role]!['gradient'][0];
  Color get lightColor => roleConfig[widget.role]!['lightColor'];
  IconData get roleIcon => roleConfig[widget.role]!['icon'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? size.width * 0.9 : 500,
                maxHeight: size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(l10n),
                  Flexible(child: _buildBody(l10n, isSmallScreen)),
                  _buildActions(l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: roleConfig[widget.role]!['gradient'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              roleIcon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addEntity(_getRoleDisplayName(widget.role, l10n)),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSubtitle(l10n),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            children: _buildFormFieldsForRole(l10n, isSmallScreen),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.cancel,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AnimatedBuilder(
              animation: _submitController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: roleConfig[widget.role]!['gradient'],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _onAddPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            _getActionIcon(),
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      _isSubmitting ? 'Adding...' : l10n.add,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormFieldsForRole(
      AppLocalizations l10n, bool isSmallScreen) {
    switch (widget.role) {
      case 'coach':
        return _buildCoachFields(l10n, isSmallScreen);
      case 'player':
        return _buildPlayerFields(l10n, isSmallScreen);
      case 'team':
        return _buildTeamFields(l10n, isSmallScreen);
      default:
        return [];
    }
  }

  List<Widget> _buildCoachFields(AppLocalizations l10n, bool isSmallScreen) {
    return [
      // Profile Image Section
      _buildImageSection(l10n),
      const SizedBox(height: 24),

      // Personal Information
      _buildSectionHeader('Personal Information', Icons.person_rounded),
      const SizedBox(height: 16),

      _buildTextField(
        label: l10n.name,
        icon: Icons.person_outline_rounded,
        validator: (value) => value!.isEmpty ? "Enter a name" : null,
        onSaved: (value) => name = value!.trim(),
        focusNode: _focusNodes[0],
        nextFocusNode: _focusNodes[1],
      ),
      const SizedBox(height: 16),

      _buildTextField(
        label: l10n.email,
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        validator: (value) => value!.isEmpty ? "Enter an email" : null,
        onSaved: (value) => email = value!.trim(),
        focusNode: _focusNodes[1],
        nextFocusNode: _focusNodes[2],
      ),
      const SizedBox(height: 16),

      _buildPasswordField(l10n),
      const SizedBox(height: 16),

      _buildTextField(
        label: l10n.roleDescription,
        icon: Icons.description_outlined,
        maxLines: 2,
        onSaved: (value) => roleDescription = value ?? "",
        focusNode: _focusNodes[3],
      ),
      const SizedBox(height: 24),

      // Team Assignment
      _buildSectionHeader('Team Assignment', Icons.groups_rounded),
      const SizedBox(height: 16),
      _buildTeamDropdown(l10n, isCoach: true),
    ];
  }

  List<Widget> _buildPlayerFields(AppLocalizations l10n, bool isSmallScreen) {
    return [
      // Personal Information
      _buildSectionHeader('Player Information', Icons.sports_rounded),
      const SizedBox(height: 16),

      _buildTextField(
        label: l10n.name,
        icon: Icons.person_outline_rounded,
        validator: (value) => value!.isEmpty ? "Enter player name" : null,
        onSaved: (value) => name = value!.trim(),
        focusNode: _focusNodes[0],
        nextFocusNode: _focusNodes[1],
      ),
      const SizedBox(height: 16),

      _buildDateField(l10n),
      const SizedBox(height: 16),

      _buildTextField(
        label: l10n.position,
        icon: Icons.sports_soccer_rounded,
        validator: (value) => value!.isEmpty ? "Enter position" : null,
        onSaved: (value) => position = value!.trim(),
        focusNode: _focusNodes[1],
        nextFocusNode: _focusNodes[2],
      ),
      const SizedBox(height: 24),

      // Team Assignment
      _buildSectionHeader('Team Assignment', Icons.groups_rounded),
      const SizedBox(height: 16),
      _buildTeamDropdown(l10n, isCoach: false),
    ];
  }

  List<Widget> _buildTeamFields(AppLocalizations l10n, bool isSmallScreen) {
    return [
      // Team Information
      _buildSectionHeader('Team Information', Icons.groups_rounded),
      const SizedBox(height: 16),

      _buildTextField(
        label: l10n.teamName,
        icon: Icons.group_outlined,
        validator: (value) => value!.isEmpty ? "Enter team name" : null,
        onSaved: (value) => teamName = value!.trim(),
        focusNode: _focusNodes[0],
        nextFocusNode: _focusNodes[1],
      ),
      const SizedBox(height: 16),

      _buildTextField(
        label: "Team Description",
        icon: Icons.description_outlined,
        maxLines: 2,
        validator: (value) => value!.isEmpty ? "Enter team description" : null,
        onSaved: (value) => teamDescription = value!.trim(),
        focusNode: _focusNodes[1],
      ),
      const SizedBox(height: 24),

      // Coach Assignment
      _buildSectionHeader('Coach Assignment', Icons.sports_rounded),
      const SizedBox(height: 16),
      _buildCoachDropdown(l10n),
    ];
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: lightColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (focusNode?.hasFocus == true)
              ? primaryColor
              : Colors.grey.shade300,
          width: (focusNode?.hasFocus == true) ? 2 : 1,
        ),
        boxShadow: (focusNode?.hasFocus == true)
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: TextFormField(
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction:
            nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: (_) {
          if (nextFocusNode != null) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          }
        },
        validator: validator,
        onSaved: onSaved,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          prefixIcon: Icon(
            icon,
            color: (focusNode?.hasFocus == true)
                ? primaryColor
                : Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField(AppLocalizations l10n) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              (_focusNodes[2].hasFocus) ? primaryColor : Colors.grey.shade300,
          width: (_focusNodes[2].hasFocus) ? 2 : 1,
        ),
        boxShadow: (_focusNodes[2].hasFocus)
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: TextFormField(
        focusNode: _focusNodes[2],
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) =>
            FocusScope.of(context).requestFocus(_focusNodes[3]),
        validator: (value) =>
            value!.length < 6 ? "Password must be at least 6 characters" : null,
        onSaved: (value) => password = value!,
        decoration: InputDecoration(
          labelText: l10n.password,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color:
                (_focusNodes[2].hasFocus) ? primaryColor : Colors.grey.shade500,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: Colors.grey.shade500,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDateField(AppLocalizations l10n) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate:
                DateTime.now().subtract(const Duration(days: 365 * 10)),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (pickedDate != null) {
            setState(() => birthDate = pickedDate);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  birthDate == null
                      ? 'Select birth date'
                      : DateFormat('MMMM dd, yyyy').format(birthDate!),
                  style: GoogleFonts.poppins(
                    color: birthDate == null
                        ? Colors.grey.shade500
                        : Colors.grey.shade800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (birthDate != null)
                IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.grey.shade500),
                  onPressed: () => setState(() => birthDate = null),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamDropdown(AppLocalizations l10n, {required bool isCoach}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teams').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading teams...',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        List<DropdownMenuItem<String>> teamItems =
            snapshot.data!.docs.map<DropdownMenuItem<String>>((doc) {
          final tName = doc['team_name'] as String;
          return DropdownMenuItem<String>(
            value: tName,
            child: Text(
              tName,
              style: GoogleFonts.poppins(),
            ),
          );
        }).toList();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: isCoach ? 'Assign to Team' : l10n.selectTeam,
              labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
              prefixIcon:
                  Icon(Icons.groups_outlined, color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: teamItems,
            onChanged: (value) {
              if (isCoach) {
                selectedTeamForCoach = value;
              } else {
                selectedTeamForPlayer = value;
              }
            },
            dropdownColor: Colors.white,
            style: GoogleFonts.poppins(color: Colors.grey.shade800),
          ),
        );
      },
    );
  }

  Widget _buildCoachDropdown(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading coaches...',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        List<DropdownMenuItem<String>> coachItems =
            snapshot.data!.docs.map<DropdownMenuItem<String>>((doc) {
          final coachName = doc['name'];
          final coachId = doc.id;
          return DropdownMenuItem<String>(
            value: coachId,
            child: Text(
              coachName,
              style: GoogleFonts.poppins(),
            ),
          );
        }).toList();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: l10n.assignCoach,
              labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.person_outline_rounded,
                  color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: coachItems,
            onChanged: (value) => selectedCoachForTeam = value,
            dropdownColor: Colors.white,
            style: GoogleFonts.poppins(color: Colors.grey.shade800),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(AppLocalizations l10n) {
    return Column(
      children: [
        _buildSectionHeader('Profile Picture', Icons.camera_alt_rounded),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: roleConfig[widget.role]!['gradient'],
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (_imageFile != null) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: roleConfig[widget.role]!['gradient'],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadToCloudinary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.cloud_upload_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload Image',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ] else ...[
          Text(
            'Tap the circle above to select a profile picture',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // Helper methods
  String _getRoleDisplayName(String role, AppLocalizations l10n) {
    switch (role) {
      case 'coach':
        return l10n.coaches.substring(0, l10n.coaches.length - 1);
      case 'player':
        return l10n.players.substring(0, l10n.players.length - 1);
      case 'team':
        return l10n.teams.substring(0, l10n.teams.length - 1);
      default:
        return role.capitalize();
    }
  }

  String _getSubtitle(AppLocalizations l10n) {
    switch (widget.role) {
      case 'coach':
        return 'Add a new coach to the system';
      case 'player':
        return 'Register a new player';
      case 'team':
        return 'Create a new team';
      default:
        return 'Add new entry';
    }
  }

  IconData _getActionIcon() {
    switch (widget.role) {
      case 'coach':
        return Icons.person_add_rounded;
      case 'player':
        return Icons.person_add_rounded;
      case 'team':
        return Icons.group_add_rounded;
      default:
        return Icons.add_rounded;
    }
  }

  // Image handling methods
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
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
        _showSuccessSnackBar('Image uploaded successfully!');
      } else {
        throw Exception(jsonData['error']['message']);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showErrorSnackBar('Upload failed: $e');
    }
  }

  // Data submission methods
  void _onAddPressed() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    _submitController.forward();

    try {
      switch (widget.role) {
        case 'coach':
          await _addCoach();
          break;
        case 'player':
          await _addPlayer();
          break;
        case 'team':
          await _addTeam();
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _submitController.reverse();
      }
    }
  }

  Future<void> _addCoach() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_uploadedImageUrl == null) {
      _showErrorSnackBar("Please upload an image for the coach.");
      return;
    }

    try {
      // Create coach in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String coachUID = userCredential.user!.uid;

      // Save coach details in users collection
      await FirebaseFirestore.instance.collection('users').doc(coachUID).set({
        "name": name,
        "email": email,
        "role": "coach",
        "role_description": roleDescription,
        "team": selectedTeamForCoach ?? "Unassigned",
        "picture": _uploadedImageUrl,
        "created_at": Timestamp.now(),
      });

      // Update the selected team with coach UID
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
              .update({'coach': coachUID});
        }
      }

      _showSuccessSnackBar('Coach added successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Error adding coach: $e');
    }
  }

  Future<void> _addPlayer() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (selectedTeamForPlayer == null || selectedTeamForPlayer!.isEmpty) {
      _showErrorSnackBar("Please select a team for the player.");
      return;
    }

    try {
      // Find the team document by its name
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
          'created_at': Timestamp.now(),
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

      // Add the player to the players collection
      await FirebaseFirestore.instance.collection('players').add({
        "name": name,
        "birth_date": birthDate != null ? Timestamp.fromDate(birthDate!) : null,
        "position": position,
        "team": selectedTeamForPlayer,
        "created_at": Timestamp.now(),
      });

      _showSuccessSnackBar('Player added successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Error adding player: $e');
    }
  }

  Future<void> _addTeam() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      await FirebaseFirestore.instance.collection('teams').add({
        "team_name": teamName,
        "team_description": teamDescription,
        "number_of_players": 0,
        "coach": selectedCoachForTeam ?? "",
        "created_at": Timestamp.now(),
      });

      _showSuccessSnackBar('Team created successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Error adding team: $e');
    }
  }

  // Utility methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Stream<QuerySnapshot> getTeamsStream() {
    return FirebaseFirestore.instance.collection('teams').snapshots();
  }
}

// String extension for capitalizing
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
