import '../../../../core/errors/result.dart';
import '../../../../core/networking/api_client.dart';
import '../models/dashboard_stats.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<Result<DashboardStats>> getDashboardStats() async {
    try {
      final response = await _apiClient.get('/api/v1/dashboard/stats');
      final stats = DashboardStats.fromJson(response.data);
      return Result.success(stats);
    } on ApiException catch (e) {
      return Result.failure(e.message);
    } catch (e) {
      return Result.failure('Failed to fetch dashboard stats: $e');
    }
  }

  Future<Result<SystemHealth>> getSystemHealth() async {
    try {
      final response = await _apiClient.get('/health');
      final health = SystemHealth.fromJson(response.data);
      return Result.success(health);
    } on ApiException catch (e) {
      return Result.failure(e.message);
    } catch (e) {
      return Result.failure('Failed to fetch system health: $e');
    }
  }
}
