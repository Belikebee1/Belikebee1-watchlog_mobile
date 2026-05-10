/// One-line per-day summary returned by `GET /api/v1/reports`.
class ReportSummary {
  final String date; // YYYY-MM-DD
  final String worstSeverity;
  final int runs;
  final DateTime? lastRanAt;

  const ReportSummary({
    required this.date,
    required this.worstSeverity,
    required this.runs,
    this.lastRanAt,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        date: (json['date'] as String?) ?? '?',
        worstSeverity: (json['worst_severity'] as String?) ?? 'OK',
        runs: (json['runs'] as int?) ?? 0,
        lastRanAt: _parseIso(json['last_ran_at']),
      );

  static DateTime? _parseIso(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}

/// One single watchlog run (a `watchlog run` invocation), as returned
/// in the per-day archive `GET /api/v1/reports/{date}`.
class ReportRun {
  final DateTime ranAt;
  final List<ReportCheck> results;

  const ReportRun({required this.ranAt, required this.results});

  factory ReportRun.fromJson(Map<String, dynamic> json) {
    final ranRaw = json['ran_at'] as String?;
    final ran = ranRaw != null ? DateTime.tryParse(ranRaw) : null;
    return ReportRun(
      ranAt: ran ?? DateTime.now().toUtc(),
      results: ((json['results'] as List?) ?? [])
          .map((e) => ReportCheck.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// One check's recorded result inside a run archive. Same shape as
/// CheckResult.to_dict() on the backend.
class ReportCheck {
  final String check;
  final String severity;
  final String title;
  final String summary;

  const ReportCheck({
    required this.check,
    required this.severity,
    required this.title,
    required this.summary,
  });

  factory ReportCheck.fromJson(Map<String, dynamic> json) => ReportCheck(
        check: (json['check'] as String?) ?? '?',
        severity: (json['severity'] as String?) ?? 'OK',
        title: (json['title'] as String?) ?? '',
        summary: (json['summary'] as String?) ?? '',
      );
}
