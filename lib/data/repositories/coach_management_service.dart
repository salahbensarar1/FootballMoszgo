import 'package:footballtraining/data/repositories/team_service.dart';
import 'package:footballtraining/data/repositories/user_service.dart';

class CoachManagementService {
  final TeamService _teamService = TeamService();
  final UserService _userService = UserService();

  Future<void> deleteCoachCompletely(String coachUserId) async {
    final coach = await _userService.getUserById(coachUserId);
    if (coach == null) throw Exception('Coach not found');
    if (coach.role != 'coach') throw Exception('User is not a coach');

    await _teamService.deleteCoachCompletely(coachUserId);
    await _userService.deleteUser(coachUserId);
  }
}
