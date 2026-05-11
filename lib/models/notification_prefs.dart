/// Per-server notification preferences. Mirror of the backend's
/// [auth._default_notification_prefs()] schema.
///
/// Quiet hours interpretation:
///   * window is local time on the *device* — backend stores the
///     [quietTimezone] sent by mobile so any host evaluates it the same
///   * `quiet_end <= quiet_start` is allowed and means "spans midnight"
///     (e.g. start=22:00, end=07:00)
///   * inside the window, alerts at or above [quietMinSeverity] still
///     deliver; everything else is suppressed
///
/// Severity ordering: OK < INFO < WARN < CRITICAL.
class NotificationPreferences {
  final bool quietHoursEnabled;
  final String quietStart;
  final String quietEnd;
  final String? quietTimezone;
  final String quietMinSeverity;
  final String minSeverity;
  final List<String> disabledChecks;
  final int cooldownHours;

  const NotificationPreferences({
    required this.quietHoursEnabled,
    required this.quietStart,
    required this.quietEnd,
    required this.quietTimezone,
    required this.quietMinSeverity,
    required this.minSeverity,
    required this.disabledChecks,
    required this.cooldownHours,
  });

  static const defaults = NotificationPreferences(
    quietHoursEnabled: false,
    quietStart: '22:00',
    quietEnd: '07:00',
    quietTimezone: null,
    quietMinSeverity: 'CRITICAL',
    minSeverity: 'WARN',
    disabledChecks: [],
    cooldownHours: 12,
  );

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
        quietStart: (json['quiet_start'] as String?) ?? '22:00',
        quietEnd: (json['quiet_end'] as String?) ?? '07:00',
        quietTimezone: json['quiet_timezone'] as String?,
        quietMinSeverity:
            (json['quiet_min_severity'] as String? ?? 'CRITICAL').toUpperCase(),
        minSeverity:
            (json['min_severity'] as String? ?? 'WARN').toUpperCase(),
        disabledChecks: ((json['disabled_checks'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        cooldownHours: (json['cooldown_hours'] as int?) ?? 12,
      );

  Map<String, dynamic> toJson() => {
        'quiet_hours_enabled': quietHoursEnabled,
        'quiet_start': quietStart,
        'quiet_end': quietEnd,
        if (quietTimezone != null) 'quiet_timezone': quietTimezone,
        'quiet_min_severity': quietMinSeverity,
        'min_severity': minSeverity,
        'disabled_checks': disabledChecks,
        'cooldown_hours': cooldownHours,
      };

  NotificationPreferences copyWith({
    bool? quietHoursEnabled,
    String? quietStart,
    String? quietEnd,
    String? quietTimezone,
    String? quietMinSeverity,
    String? minSeverity,
    List<String>? disabledChecks,
    int? cooldownHours,
  }) =>
      NotificationPreferences(
        quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
        quietStart: quietStart ?? this.quietStart,
        quietEnd: quietEnd ?? this.quietEnd,
        quietTimezone: quietTimezone ?? this.quietTimezone,
        quietMinSeverity: quietMinSeverity ?? this.quietMinSeverity,
        minSeverity: minSeverity ?? this.minSeverity,
        disabledChecks: disabledChecks ?? this.disabledChecks,
        cooldownHours: cooldownHours ?? this.cooldownHours,
      );
}
