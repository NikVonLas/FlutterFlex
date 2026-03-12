import '../models/dashboard_summary.dart';
import 'api_service.dart';

class DashboardService {
  const DashboardService(this._apiService);

  final ApiService _apiService;

  Future<DashboardSummary> fetchSummary() async {
    final response =
        await _apiService.get('/dashboard/summary', authenticated: true)
            as Map<String, dynamic>;

    return DashboardSummary.fromJson(response);
  }
}
