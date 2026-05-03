/// Models matching the watchlog REST API responses.
/// See https://github.com/Belikebee1/watchlog#rest-api--web-dashboard-v03

class Status {
  final int schemaVersion;
  final DateTime ranAt;
  final String host;
  final String watchlogVersion;
  final String worstSeverity;
  final int checksTotal;
  final Map<String, int> counts;
  final List<Actionable> actionable;
  final int? ageSeconds;

  Status({
    required this.schemaVersion,
    required this.ranAt,
    required this.host,
    required this.watchlogVersion,
    required this.worstSeverity,
    required this.checksTotal,
    required this.counts,
    required this.actionable,
    this.ageSeconds,
  });

  factory Status.fromJson(Map<String, dynamic> json) => Status(
        schemaVersion: json['schema_version'] as int? ?? 1,
        ranAt: DateTime.parse(json['ran_at'] as String),
        host: json['host'] as String? ?? 'unknown',
        watchlogVersion: json['watchlog_version'] as String? ?? '?',
        worstSeverity: json['worst_severity'] as String? ?? 'OK',
        checksTotal: json['checks_total'] as int? ?? 0,
        counts: Map<String, int>.from(json['counts'] as Map? ?? {}),
        actionable: ((json['actionable'] as List?) ?? [])
            .map((e) => Actionable.fromJson(e as Map<String, dynamic>))
            .toList(),
        ageSeconds: json['age_seconds'] as int?,
      );

  Duration get age => Duration(
      seconds: ageSeconds ?? DateTime.now().difference(ranAt.toUtc()).inSeconds);
}

class Actionable {
  final String check;
  final String severity;
  final String title;

  Actionable({required this.check, required this.severity, required this.title});

  factory Actionable.fromJson(Map<String, dynamic> json) => Actionable(
        check: json['check'] as String,
        severity: json['severity'] as String,
        title: json['title'] as String,
      );
}

class StateData {
  final Map<String, SnoozeEntry> snoozes;
  final Map<String, IgnoreEntry> ignores;

  StateData({required this.snoozes, required this.ignores});

  factory StateData.fromJson(Map<String, dynamic> json) {
    final snoozes = <String, SnoozeEntry>{};
    (json['snoozes'] as Map?)?.forEach((k, v) {
      snoozes[k as String] = SnoozeEntry.fromJson(v as Map<String, dynamic>);
    });
    final ignores = <String, IgnoreEntry>{};
    (json['ignores'] as Map?)?.forEach((k, v) {
      ignores[k as String] = IgnoreEntry.fromJson(v as Map<String, dynamic>);
    });
    return StateData(snoozes: snoozes, ignores: ignores);
  }
}

class SnoozeEntry {
  final DateTime until;
  final String by;
  SnoozeEntry({required this.until, required this.by});
  factory SnoozeEntry.fromJson(Map<String, dynamic> json) => SnoozeEntry(
        until: DateTime.parse(json['until'] as String),
        by: json['by'] as String? ?? '?',
      );
}

class IgnoreEntry {
  final DateTime since;
  final String by;
  IgnoreEntry({required this.since, required this.by});
  factory IgnoreEntry.fromJson(Map<String, dynamic> json) => IgnoreEntry(
        since: DateTime.parse(json['since'] as String),
        by: json['by'] as String? ?? '?',
      );
}

class ActionResult {
  final bool ok;
  final int exitCode;
  final String output;
  final String command;

  ActionResult({
    required this.ok,
    required this.exitCode,
    required this.output,
    required this.command,
  });

  factory ActionResult.fromJson(Map<String, dynamic> json) => ActionResult(
        ok: json['ok'] as bool? ?? false,
        exitCode: json['exit_code'] as int? ?? -1,
        output: json['output'] as String? ?? '',
        command: json['command'] as String? ?? '',
      );
}
