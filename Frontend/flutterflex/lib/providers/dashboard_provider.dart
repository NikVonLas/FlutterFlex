import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._dashboardService);

  final DashboardService _dashboardService;

  DashboardSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _dashboardService.fetchSummary();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
