/// One actionable shortcut surfaced by the backend's `/api/v1/actions`.
///
/// `kind` discriminates the variants:
///   * 'restart_service' — POST /actions/restart-service with target as
///     the systemd unit
///   * 'reboot'          — POST /actions/reboot (operator must opt in)
///   * 'tail_logs'       — POST /actions/logs to read journalctl output
class ActionDescriptor {
  final String kind;
  final String target;
  final String label;
  final bool destructive;

  const ActionDescriptor({
    required this.kind,
    required this.target,
    required this.label,
    required this.destructive,
  });

  factory ActionDescriptor.fromJson(Map<String, dynamic> json) =>
      ActionDescriptor(
        kind: (json['kind'] as String?) ?? '?',
        target: (json['target'] as String?) ?? '',
        label: (json['label'] as String?) ?? '',
        destructive: (json['destructive'] as bool?) ?? false,
      );

  bool get isRestart => kind == 'restart_service';
  bool get isReboot => kind == 'reboot';
  bool get isTailLogs => kind == 'tail_logs';
}
