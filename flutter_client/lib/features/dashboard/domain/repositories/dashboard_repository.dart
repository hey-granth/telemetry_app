import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/networking/api_client.dart';
import '../models/dashboard_stats.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<Result<DashboardStats, AppError>> getDashboardStats() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/dashboard/stats',
    );

    return response.map((data) => DashboardStats.fromJson(data));
  }

  Future<Result<SystemHealth, AppError>> getSystemHealth() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/health',
    );

    return response.map((data) => SystemHealth.fromJson(data));
  }
}
