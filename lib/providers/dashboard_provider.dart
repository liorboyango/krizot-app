import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule_model.dart';
import '../services/dashboard_service.dart';

/// Provider for [DashboardService].
final dashboardServiceProvider =
    Provider<DashboardService>((ref) => DashboardService());

/// Dashboard stats state.
class DashboardStatsState {
  final DashboardStats? stats;
  final bool isLoading;
  final String? error;

  const DashboardStatsState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  DashboardStatsState copyWith({
    DashboardStats? stats,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DashboardStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider for dashboard statistics.
final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardStatsNotifier, DashboardStatsState>(
        DashboardStatsNotifier.new);

/// Notifier managing dashboard stats.
class DashboardStatsNotifier extends AsyncNotifier<DashboardStatsState> {
  late DashboardService _service;

  @override
  Future<DashboardStatsState> build() async {
    _service = ref.read(dashboardServiceProvider);
    return _fetchStats();
  }

  Future<DashboardStatsState> _fetchStats() async {
    try {
      final stats = await _service.getStats();
      return DashboardStatsState(stats: stats);
    } catch (e) {
      return DashboardStatsState(error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Refreshes dashboard statistics.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetchStats());
  }
}
