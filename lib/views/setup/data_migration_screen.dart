import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footballtraining/services/data_migration_service.dart';
import 'package:footballtraining/views/login/login_page.dart';

class DataMigrationScreen extends StatefulWidget {
  const DataMigrationScreen({super.key});

  @override
  State<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _orgDescriptionController = TextEditingController();
  final _adminEmailController = TextEditingController();

  bool _isMigrating = false;
  String? _migrationStatus;
  bool _migrationCompleted = false;

  @override
  void dispose() {
    _orgNameController.dispose();
    _orgDescriptionController.dispose();
    _adminEmailController.dispose();
    super.dispose();
  }

  Future<void> _startMigration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isMigrating = true;
      _migrationStatus = 'Starting migration...';
    });

    try {
      final organizationId =
          await DataMigrationService.migrateToOrganizationStructure(
        organizationName: _orgNameController.text.trim(),
        organizationDescription: _orgDescriptionController.text.trim(),
        adminEmail: _adminEmailController.text.trim().isNotEmpty
            ? _adminEmailController.text.trim()
            : null,
      );

      setState(() {
        _migrationStatus =
            'Migration completed successfully!\nOrganization ID: $organizationId';
        _migrationCompleted = true;
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _migrationStatus = 'Migration failed: $e';
      });

      HapticFeedback.lightImpact();
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Data Migration'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.transform,
                        color: Colors.blue.shade600,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Migrate to Organization Structure',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This will convert your flat collections (users, teams, players) into a multi-tenant organization structure.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'This operation will modify your database structure. Make sure you have a backup!',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Migration Form
            if (!_migrationCompleted) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Organization Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Organization Name
                      TextFormField(
                        controller: _orgNameController,
                        decoration: InputDecoration(
                          labelText: 'Organization Name *',
                          hintText: 'e.g., Football Academy Budapest',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Organization name is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Organization Description
                      TextFormField(
                        controller: _orgDescriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Brief description of your organization...',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Admin Email (Optional)
                      TextFormField(
                        controller: _adminEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Admin Email (Optional)',
                          hintText: 'admin@example.com',
                          prefixIcon: const Icon(Icons.admin_panel_settings),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Migration Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isMigrating ? null : _startMigration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isMigrating
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Migrating...',
                                        style: TextStyle(fontSize: 16)),
                                  ],
                                )
                              : const Text(
                                  'Start Migration',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Migration Status
            if (_migrationStatus != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _migrationCompleted
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _migrationCompleted
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _migrationCompleted
                              ? Icons.check_circle
                              : Icons.error,
                          color: _migrationCompleted
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _migrationCompleted
                              ? 'Migration Successful!'
                              : 'Migration Failed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _migrationCompleted
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _migrationStatus!,
                      style: TextStyle(
                        fontSize: 14,
                        color: _migrationCompleted
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        height: 1.4,
                      ),
                    ),
                    if (_migrationCompleted) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Continue to Login'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
