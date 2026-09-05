import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report_api.dart';
import '../domain/daily_report.dart';

class DailyReportState {
  final DailyReport? report;
  final bool loading;
  final String? error;

  const DailyReportState({this.report, this.loading = false, this.error});

  DailyReportState copyWith({DailyReport? report, bool? loading, String? error}) => DailyReportState(
        report: report ?? this.report,
        loading: loading ?? this.loading,
        error: error,
      );
}

final dailyReportControllerProvider =
    NotifierProvider<DailyReportController, DailyReportState>(DailyReportController.new);

class DailyReportController extends Notifier<DailyReportState> {
  @override
  DailyReportState build() {
    Future.microtask(loadLatest);
    return const DailyReportState(loading: true);
  }

  Future<void> loadLatest() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final report = await ref.read(reportApiProvider).latest();
      state = state.copyWith(report: report, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> generateNow() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final report = await ref.read(reportApiProvider).generate();
      state = state.copyWith(report: report, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
