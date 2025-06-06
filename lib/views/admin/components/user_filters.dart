// File: lib/views/admin/components/user_filters.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String? selectedRoleFilter;
  final Function(String) onSearchChanged;
  final Function(String?) onRoleFilterChanged;

  const UserFilters({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedRoleFilter,
    required this.onSearchChanged,
    required this.onRoleFilterChanged,
  });

  final List<String> roleOptions = const [
    'All',
    'coach',
    'admin',
    'receptionist'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSearchBar(),
          SizedBox(height: 16),
          _buildRoleFilters(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFF27121).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.search_rounded,
              color: Color(0xFFF27121),
              size: 20,
            ),
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged("");
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRoleFilters() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: roleOptions.length,
        separatorBuilder: (context, index) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final role = roleOptions[index];
          final isSelected = selectedRoleFilter == role ||
              (selectedRoleFilter == null && role == 'All');

          return _buildFilterChip(role, isSelected);
        },
      ),
    );
  }

  Widget _buildFilterChip(String role, bool isSelected) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getRoleIcon(role),
              size: 16,
              color: isSelected ? Colors.white : _getRoleColor(role),
            ),
            SizedBox(width: 6),
            Text(
              _getRoleDisplayName(role),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        selectedColor: Color(0xFFF27121),
        checkmarkColor: Colors.white,
        onSelected: (selected) {
          onRoleFilterChanged(selected ? (role == 'All' ? null : role) : null);
        },
        elevation: isSelected ? 4 : 1,
        shadowColor: isSelected
            ? Color(0xFFF27121).withOpacity(0.3)
            : Colors.grey.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Color(0xFFF27121) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'All':
        return 'All Roles';
      case 'coach':
        return 'Coaches';
      case 'admin':
        return 'Admins';
      case 'receptionist':
        return 'Receptionists';
      default:
        return role.toUpperCase();
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'all':
        return Color(0xFFF27121);
      case 'admin':
        return Colors.red.shade600;
      case 'coach':
        return Colors.blue.shade600;
      case 'receptionist':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'all':
        return Icons.people_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'coach':
        return Icons.sports_rounded;
      case 'receptionist':
        return Icons.desk_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}
