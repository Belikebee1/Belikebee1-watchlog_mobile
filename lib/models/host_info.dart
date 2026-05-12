/// Server metadata returned by /api/v1/host.
///
/// Every field is nullable on purpose — the backend ships best-effort
/// detection (parses /etc/os-release, /proc/uptime, etc.) and on hosts
/// that don't expose a particular file, the corresponding field comes
/// back as null. The UI hides null rows rather than rendering "unknown".
class HostInfo {
  final String hostname;
  final String? fqdn;
  final OsRelease? os;
  final String? kernel;
  final String? arch;
  final int? cpuCores;
  final String? cpuModel;
  final int? ramTotalMb;
  final int? diskTotalGb;
  final int? uptimeSeconds;
  final DateTime? bootTime;
  final List<HostIp> ipAddresses;
  final String? timezone;
  // Installed watchlog package version on the server. Null on older
  // servers that pre-date /api/v1/host exposing this field — the
  // update-available banner stays hidden in that case.
  final String? watchlogVersion;

  const HostInfo({
    required this.hostname,
    this.fqdn,
    this.os,
    this.kernel,
    this.arch,
    this.cpuCores,
    this.cpuModel,
    this.ramTotalMb,
    this.diskTotalGb,
    this.uptimeSeconds,
    this.bootTime,
    this.ipAddresses = const [],
    this.timezone,
    this.watchlogVersion,
  });

  factory HostInfo.fromJson(Map<String, dynamic> json) => HostInfo(
        hostname: (json['hostname'] as String?) ?? 'unknown',
        fqdn: json['fqdn'] as String?,
        os: json['os'] is Map<String, dynamic>
            ? OsRelease.fromJson(json['os'] as Map<String, dynamic>)
            : null,
        kernel: json['kernel'] as String?,
        arch: json['arch'] as String?,
        cpuCores: json['cpu_cores'] as int?,
        cpuModel: json['cpu_model'] as String?,
        ramTotalMb: json['ram_total_mb'] as int?,
        diskTotalGb: json['disk_total_gb'] as int?,
        uptimeSeconds: json['uptime_seconds'] as int?,
        bootTime: _parseIso(json['boot_time_iso']),
        ipAddresses: ((json['ip_addresses'] as List?) ?? [])
            .map((e) => HostIp.fromJson(e as Map<String, dynamic>))
            .toList(),
        timezone: json['timezone'] as String?,
        watchlogVersion: json['watchlog_version'] as String?,
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

class OsRelease {
  final String? name;
  final String? version;
  final String? prettyName;
  final String? id;

  const OsRelease({this.name, this.version, this.prettyName, this.id});

  factory OsRelease.fromJson(Map<String, dynamic> json) => OsRelease(
        name: json['name'] as String?,
        version: json['version'] as String?,
        prettyName: json['pretty_name'] as String?,
        id: json['id'] as String?,
      );

  /// Best-effort label for the OS. Prefer pretty_name (Ubuntu 24.04.4 LTS)
  /// → name + version (Ubuntu 24.04.4) → name → null.
  String? get label {
    if (prettyName != null && prettyName!.isNotEmpty) return prettyName;
    if (name != null && version != null) return '$name $version';
    return name;
  }
}

class HostIp {
  final String interface;
  final String addr;
  final String family; // ipv4 | ipv6
  const HostIp({
    required this.interface,
    required this.addr,
    required this.family,
  });

  bool get isIpv4 => family == 'ipv4';
  bool get isIpv6 => family == 'ipv6';

  factory HostIp.fromJson(Map<String, dynamic> json) => HostIp(
        interface: (json['interface'] as String?) ?? '?',
        addr: (json['addr'] as String?) ?? '',
        family: (json['family'] as String?) ?? 'ipv4',
      );
}
