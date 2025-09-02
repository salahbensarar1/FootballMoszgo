import 'package:flutter/material.dart';
import 'package:footballtraining/services/sample_data_generator_service.dart';
import 'package:footballtraining/services/logging_service.dart';

/// Debug screen for generating sample data for testing multi-tenant isolation
class SampleDataGeneratorScreen extends StatefulWidget {
  const SampleDataGeneratorScreen({super.key});

  @override
  State<SampleDataGeneratorScreen> createState() =>
      _SampleDataGeneratorScreenState();
}

class _SampleDataGeneratorScreenState extends State<SampleDataGeneratorScreen> {
  final _generatorService = SampleDataGeneratorService();

  bool _isGenerating = false;
  List<String> _createdClubIds = [];
  List<Map<String, String>> _testCredentials = [];
  String? _errorMessage;

  int _numberOfClubs = 3;
  int _teamsPerClub = 3;
  int _playersPerTeam = 15;
  int _coachesPerClub = 4;

  Future<void> _generateSampleData() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _createdClubIds.clear();
      _testCredentials.clear();
    });

    try {
      LoggingService.info('🚀 Starting sample data generation...');

      // Generate multiple clubs with data
      final clubIds = await _generatorService.generateMultipleClubsData(
        numberOfClubs: _numberOfClubs,
        teamsPerClub: _teamsPerClub,
        playersPerTeam: _playersPerTeam,
        coachesPerClub: _coachesPerClub,
      );

      // Generate test credentials
      final credentials =
          await _generatorService.generateTestCredentials(_numberOfClubs);

      setState(() {
        _createdClubIds = clubIds;
        _testCredentials = credentials;
      });

      LoggingService.info('✅ Sample data generation completed successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully created ${clubIds.length} clubs with sample data!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      LoggingService.error('❌ Sample data generation failed', e);
      setState(() {
        _errorMessage = 'Failed to generate sample data: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Data Generator'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generation Configuration',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildSlider(
                      label: 'Number of Clubs',
                      value: _numberOfClubs.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (value) =>
                          setState(() => _numberOfClubs = value.toInt()),
                    ),
                    _buildSlider(
                      label: 'Teams per Club',
                      value: _teamsPerClub.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      onChanged: (value) =>
                          setState(() => _teamsPerClub = value.toInt()),
                    ),
                    _buildSlider(
                      label: 'Players per Team',
                      value: _playersPerTeam.toDouble(),
                      min: 5,
                      max: 25,
                      divisions: 20,
                      onChanged: (value) =>
                          setState(() => _playersPerTeam = value.toInt()),
                    ),
                    _buildSlider(
                      label: 'Coaches per Club',
                      value: _coachesPerClub.toDouble(),
                      min: 2,
                      max: 8,
                      divisions: 6,
                      onChanged: (value) =>
                          setState(() => _coachesPerClub = value.toInt()),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This will create $_numberOfClubs football clubs, each with $_teamsPerClub teams, '
                      '$_playersPerTeam players per team, and $_coachesPerClub coaches.',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateSampleData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isGenerating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Generating Sample Data...'),
                        ],
                      )
                    : const Text(
                        'Generate Sample Data',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Results section
            if (_createdClubIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generated ${_createdClubIds.length} Football Clubs',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Test Login Credentials:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _testCredentials.length,
                            itemBuilder: (context, index) {
                              final cred = _testCredentials[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(cred['club_name']!),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Email: ${cred['admin_email']}'),
                                      Text(
                                          'Password: ${cred['admin_password']}'),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      // Copy credentials to clipboard
                                      // final text = '${cred['admin_email']}\n${cred['admin_password']}';
                                      // TODO: Implement clipboard copy functionality
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Credentials ready to copy'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info,
                                      color: Colors.blue, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Test Instructions:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                  '1. Use any of the email/password combinations above to login'),
                              Text('2. Each club has completely isolated data'),
                              Text(
                                  '3. Admins can only see their own club\'s data'),
                              Text('4. Switch between clubs to test isolation'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toInt().toString()),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: _isGenerating ? null : onChanged,
        ),
      ],
    );
  }
}
