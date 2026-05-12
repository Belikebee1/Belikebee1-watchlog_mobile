/// One published GitHub release of a watchlog repository.
///
/// We only care about a handful of fields — the tag (which carries the
/// SemVer version we compare against), the public URL (so the banner
/// can open release notes), and the published timestamp (for the
/// "released X ago" hint).
class GithubRelease {
  /// Raw tag name as it appears on GitHub, e.g. "v0.6.0" or "0.6.0".
  final String tag;

  /// Tag stripped of a leading "v", giving the pure SemVer string used
  /// for comparisons. Empty when [tag] was already empty.
  final String version;

  final String name;
  final String htmlUrl;
  final DateTime? publishedAt;
  final String body;
  final bool isPrerelease;

  const GithubRelease({
    required this.tag,
    required this.version,
    required this.name,
    required this.htmlUrl,
    required this.publishedAt,
    required this.body,
    required this.isPrerelease,
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String?) ?? '';
    return GithubRelease(
      tag: tag,
      version: tag.startsWith('v') ? tag.substring(1) : tag,
      name: (json['name'] as String?) ?? tag,
      htmlUrl: (json['html_url'] as String?) ?? '',
      publishedAt: _parseIso(json['published_at']),
      body: (json['body'] as String?) ?? '',
      isPrerelease: (json['prerelease'] as bool?) ?? false,
    );
  }

  static DateTime? _parseIso(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
