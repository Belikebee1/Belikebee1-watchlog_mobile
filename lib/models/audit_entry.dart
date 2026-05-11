/// One row from `/api/v1/audit`. The backend writes free-form fields
/// per event type — we keep them in [extra] so the UI can render
/// event-specific labels without losing data the model didn't
/// anticipate.
class AuditEntry {
  final DateTime ts;
  final String event;
  final Map<String, dynamic> extra;

  const AuditEntry({
    required this.ts,
    required this.event,
    required this.extra,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    final tsRaw = json['ts'] as String?;
    final parsed =
        tsRaw != null ? DateTime.tryParse(tsRaw) : null;
    final extra = Map<String, dynamic>.from(json)
      ..remove('ts')
      ..remove('event');
    return AuditEntry(
      ts: parsed ?? DateTime.now().toUtc(),
      event: (json['event'] as String?) ?? 'UNKNOWN',
      extra: extra,
    );
  }

  /// True for events that ended in failure (denied, locked-out, etc.).
  /// The UI uses this to pick the row icon and color.
  bool get isFailure =>
      event.endsWith('_FAILED') ||
      event.endsWith('_DENIED') ||
      event.endsWith('_LOCKED_OUT') ||
      event == 'TOKEN_AUTH_FAILED' ||
      event == 'TOKEN_FORBIDDEN';
}
