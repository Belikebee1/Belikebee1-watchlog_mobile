import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/client.dart';
import '../models/server.dart';

/// Holds the list of configured watchlog servers and which one is active.
/// Persisted in platform secure storage as a single JSON blob.
class ServersState {
  final List<Server> servers;
  final String? activeId;

  const ServersState({this.servers = const [], this.activeId});

  bool get isEmpty => servers.isEmpty;
  bool get isAuthenticated => servers.isNotEmpty;

  Server? get active {
    if (servers.isEmpty) return null;
    if (activeId != null) {
      for (final s in servers) {
        if (s.id == activeId) return s;
      }
    }
    return servers.first;
  }

  ServersState copyWith({List<Server>? servers, String? activeId}) =>
      ServersState(
        servers: servers ?? this.servers,
        activeId: activeId ?? this.activeId,
      );

  Map<String, dynamic> toJson() => {
        'servers': servers.map((s) => s.toJson()).toList(),
        'activeId': activeId,
      };

  factory ServersState.fromJson(Map<String, dynamic> json) {
    final list = (json['servers'] as List<dynamic>? ?? [])
        .map((e) => Server.fromJson(e as Map<String, dynamic>))
        .toList();
    return ServersState(
      servers: list,
      activeId: json['activeId'] as String?,
    );
  }
}

class ServersNotifier extends StateNotifier<ServersState> {
  static const _kServers = 'watchlog_servers_v1';
  // Legacy single-server keys (pre-multi-server) — migrated on first load
  static const _kLegacyBaseUrl = 'watchlog_base_url';
  static const _kLegacyToken = 'watchlog_token';

  final FlutterSecureStorage _storage;

  ServersNotifier(this._storage) : super(const ServersState());

  Future<void> load() async {
    final raw = await _storage.read(key: _kServers);
    if (raw != null && raw.isNotEmpty) {
      try {
        state = ServersState.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
        return;
      } catch (_) {
        // fall through to legacy migration
      }
    }
    // Legacy migration: pre-multi-server installations stored a single
    // baseUrl + token under separate keys. Convert to a one-element list.
    final legacyUrl = await _storage.read(key: _kLegacyBaseUrl);
    final legacyToken = await _storage.read(key: _kLegacyToken);
    if (legacyUrl != null &&
        legacyUrl.isNotEmpty &&
        legacyToken != null &&
        legacyToken.isNotEmpty) {
      final migrated = Server(
        id: _newId(),
        name: _deriveNameFromUrl(legacyUrl),
        baseUrl: legacyUrl,
        token: legacyToken,
      );
      final next =
          ServersState(servers: [migrated], activeId: migrated.id);
      await _persist(next);
      await _storage.delete(key: _kLegacyBaseUrl);
      await _storage.delete(key: _kLegacyToken);
      state = next;
      return;
    }
    state = const ServersState();
  }

  Future<Server> addServer({
    required String name,
    required String baseUrl,
    required String token,
  }) async {
    final cleanedUrl =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanedName =
        name.trim().isEmpty ? _deriveNameFromUrl(cleanedUrl) : name.trim();
    final server = Server(
      id: _newId(),
      name: cleanedName,
      baseUrl: cleanedUrl,
      token: token,
    );
    final next = state.copyWith(
      servers: [...state.servers, server],
      activeId: state.activeId ?? server.id,
    );
    await _persist(next);
    state = next;
    return server;
  }

  Future<void> removeServer(String id) async {
    final remaining = state.servers.where((s) => s.id != id).toList();
    String? newActive = state.activeId;
    if (newActive == id) {
      newActive = remaining.isNotEmpty ? remaining.first.id : null;
    }
    final next = ServersState(servers: remaining, activeId: newActive);
    await _persist(next);
    state = next;
  }

  Future<void> setActive(String id) async {
    if (!state.servers.any((s) => s.id == id)) return;
    final next = state.copyWith(activeId: id);
    await _persist(next);
    state = next;
  }

  Future<void> renameServer(String id, String newName) async {
    final cleaned = newName.trim();
    if (cleaned.isEmpty) return;
    final next = state.copyWith(
      servers: [
        for (final s in state.servers)
          if (s.id == id) s.copyWith(name: cleaned) else s
      ],
    );
    await _persist(next);
    state = next;
  }

  /// Removes all configured servers. Caller is responsible for unregistering
  /// the FCM token on each server first if desired.
  Future<void> signOutAll() async {
    await _storage.delete(key: _kServers);
    state = const ServersState();
  }

  Future<void> _persist(ServersState s) async {
    await _storage.write(key: _kServers, value: jsonEncode(s.toJson()));
  }

  String _newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  String _deriveNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      if (host.isEmpty) return 'watchlog';
      // Strip "api." prefix if present so "api.watchlog.pl" → "watchlog.pl"
      return host.startsWith('api.') ? host.substring(4) : host;
    } catch (_) {
      return 'watchlog';
    }
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  ),
);

final serversProvider =
    StateNotifierProvider<ServersNotifier, ServersState>((ref) {
  return ServersNotifier(ref.watch(secureStorageProvider));
});

/// Backwards-compat alias so existing `ref.watch(authProvider)` keeps working.
final authProvider = serversProvider;

/// API client for the currently active server. Null if no servers configured.
/// Kept for code paths that operate on whichever server happens to be
/// "current" (push registration legacy, ad-hoc utilities). New screens
/// should prefer [serverApiProvider] with an explicit server id so they
/// can render any server, not just the active one.
final apiProvider = Provider<WatchlogApi?>((ref) {
  final s = ref.watch(serversProvider).active;
  if (s == null) return null;
  return WatchlogApi(baseUrl: s.baseUrl, token: s.token);
});

/// API client scoped to a specific server id. Returns null if that id no
/// longer exists in the registry (server was removed mid-flow).
final serverApiProvider = Provider.family<WatchlogApi?, String>((ref, serverId) {
  final servers = ref.watch(serversProvider).servers;
  for (final s in servers) {
    if (s.id == serverId) {
      return WatchlogApi(baseUrl: s.baseUrl, token: s.token);
    }
  }
  return null;
});

/// Look up a [Server] by id. Watching this rebuilds when the server's
/// label changes (rename), so screens stay in sync.
final serverByIdProvider = Provider.family<Server?, String>((ref, serverId) {
  final servers = ref.watch(serversProvider).servers;
  for (final s in servers) {
    if (s.id == serverId) return s;
  }
  return null;
});
