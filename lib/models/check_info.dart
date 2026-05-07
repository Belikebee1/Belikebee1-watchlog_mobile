import 'dart:ui' show Locale;

/// Bilingual explainer for a single check, returned by the backend's
/// /api/v1/checks/info endpoint. Each field is a {locale: text} map so we
/// can extend to more languages without changing the contract.
class CheckExplainer {
  final Map<String, String> title;
  final Map<String, String> what;
  final Map<String, String> why;
  final Map<String, String> remediation;

  const CheckExplainer({
    required this.title,
    required this.what,
    required this.why,
    required this.remediation,
  });

  factory CheckExplainer.fromJson(Map<String, dynamic> json) => CheckExplainer(
        title: _stringMap(json['title']),
        what: _stringMap(json['what']),
        why: _stringMap(json['why']),
        remediation: _stringMap(json['remediation']),
      );

  static Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}

/// Bilingual entry for one severity level (OK / INFO / WARN / CRITICAL).
class SeverityEntry {
  final Map<String, String> label;
  final Map<String, String> description;

  const SeverityEntry({required this.label, required this.description});

  factory SeverityEntry.fromJson(Map<String, dynamic> json) => SeverityEntry(
        label: CheckExplainer._stringMap(json['label']),
        description: CheckExplainer._stringMap(json['description']),
      );
}

/// Aggregate of everything `/api/v1/checks/info` returns.
class ChecksInfo {
  final Map<String, CheckExplainer> checks;
  final Map<String, SeverityEntry> severity;

  const ChecksInfo({required this.checks, required this.severity});

  factory ChecksInfo.fromJson(Map<String, dynamic> json) {
    final rawChecks = (json['checks'] as Map<String, dynamic>? ?? {});
    final rawSev = (json['severity'] as Map<String, dynamic>? ?? {});
    return ChecksInfo(
      checks: rawChecks.map(
        (k, v) => MapEntry(k, CheckExplainer.fromJson(v as Map<String, dynamic>)),
      ),
      severity: rawSev.map(
        (k, v) => MapEntry(k, SeverityEntry.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }

  CheckExplainer? explainerFor(String checkName) => checks[checkName];

  SeverityEntry? severityEntry(String name) => severity[name.toUpperCase()];
}

/// Picks the right text from a {locale: text} map for the user's device.
///
/// Strategy: exact match on the language code (e.g. "pl" for any Polish
/// locale), then "en" as fallback, then any value the backend happened to
/// return. This means you can add a "de" entry server-side and German
/// devices automatically pick it up without an app update.
String localizedText(Map<String, String> texts, Locale locale, {String fallback = 'en'}) {
  if (texts.isEmpty) return '';
  final code = locale.languageCode.toLowerCase();
  if (texts.containsKey(code)) return texts[code]!;
  if (texts.containsKey(fallback)) return texts[fallback]!;
  return texts.values.first;
}
