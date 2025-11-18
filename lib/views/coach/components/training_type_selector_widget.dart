import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TrainingTypeConfig {
  final String value;
  final IconData icon;
  final List<Color> gradient;

  TrainingTypeConfig(this.value, this.icon, this.gradient);
}

class TrainingTypeSelectorWidget extends StatelessWidget {
  final String? selectedTrainingType;
  final Function(String) onTrainingTypeSelected;
  final bool isTrainingActive;
  final bool isSmallScreen;

  const TrainingTypeSelectorWidget({
    super.key,
    required this.selectedTrainingType,
    required this.onTrainingTypeSelected,
    required this.isTrainingActive,
    required this.isSmallScreen,
  });

  List<TrainingTypeConfig> _getTrainingTypes(AppLocalizations l10n) => [
        TrainingTypeConfig(l10n.trainingTypeGame, Icons.sports_soccer,
            [Colors.red.shade400, Colors.red.shade600]),
        TrainingTypeConfig(l10n.trainingTypeTraining, Icons.sports,
            [Colors.blue.shade400, Colors.blue.shade600]),
        TrainingTypeConfig(l10n.trainingTypeTactical, Icons.analytics,
            [Colors.purple.shade400, Colors.purple.shade600]),
        TrainingTypeConfig(l10n.trainingTypeFitness, Icons.fitness_center,
            [Colors.orange.shade400, Colors.orange.shade600]),
        TrainingTypeConfig(
            l10n.trainingTypeTechnical,
            Icons.precision_manufacturing,
            [Colors.green.shade400, Colors.green.shade600]),
        TrainingTypeConfig(l10n.trainingTypeTheoretical, Icons.school,
            [Colors.indigo.shade400, Colors.indigo.shade600]),
        TrainingTypeConfig(l10n.trainingTypeSurvey, Icons.quiz,
            [Colors.teal.shade400, Colors.teal.shade600]),
        TrainingTypeConfig(l10n.trainingTypeMixed, Icons.shuffle,
            [Colors.amber.shade400, Colors.amber.shade600]),
      ];

  String _getLocalizedTrainingType(AppLocalizations l10n, String type) {
    switch (type) {
      case 'game':
        return 'Mérkőzés';
      case 'training':
        return 'Edzés';
      case 'tactical':
        return 'Taktikai';
      case 'fitness':
        return 'Erőnléti';
      case 'technical':
        return 'Technikai';
      case 'theoretical':
        return 'Elméleti';
      case 'survey':
        return 'Felmérés';
      case 'mixed':
        return 'Vegyes';
      default:
        return type.toUpperCase();
    }
  }

  String _getTrainingTypeDescription(AppLocalizations l10n, String type) {
    switch (type) {
      case 'game':
        return 'Official or practice matches against other teams';
      case 'training':
        return 'General training with skill development and conditioning';
      case 'tactical':
        return 'Tactical formations, strategies, and team play practice';
      case 'fitness':
        return 'Conditioning workouts, strength training, and endurance building';
      case 'technical':
        return 'Individual technical skills: dribbling, shooting, passing';
      case 'theoretical':
        return 'Tactical discussions, game rules, and strategic planning';
      case 'survey':
        return 'Player assessments, testing, and skill evaluations';
      case 'mixed':
        return 'Combined training with elements from multiple types';
      default:
        return 'Training type: $type';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width > 600 ? 4 : 4;
    final itemHeight = isSmallScreen ? 80.0 : 90.0;
    final trainingTypes = _getTrainingTypes(l10n);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              l10n.trainingType, Icons.fitness_center, isSmallScreen),
          const SizedBox(height: 12),
          SizedBox(
            height: (itemHeight * 2) + 16,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio:
                    (size.width / crossAxisCount - 20) / (itemHeight + 4),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: trainingTypes.length,
              itemBuilder: (context, index) {
                final type = trainingTypes[index];
                final isSelected = selectedTrainingType == type.value;

                return Tooltip(
                  message: _getTrainingTypeDescription(l10n, type.value),
                  preferBelow: true,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GestureDetector(
                    onTap: isTrainingActive
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            onTrainingTypeSelected(type.value);
                          },
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${_getLocalizedTrainingType(l10n, type.value)}: ${_getTrainingTypeDescription(l10n, type.value)}',
                          ),
                          duration: const Duration(seconds: 4),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: type.gradient)
                            : LinearGradient(colors: [
                                Colors.grey.shade200,
                                Colors.grey.shade300
                              ]),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: type.gradient[0], width: 2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: type.gradient[0].withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            type.icon,
                            size: isSmallScreen ? 28 : 32,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getLocalizedTrainingType(l10n, type.value),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  Widget _buildCard({required Widget child, Gradient? gradient}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? Colors.white : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isSmallScreen) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF27121), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
