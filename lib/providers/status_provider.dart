import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import 'auth_provider.dart';

/// Polls /api/v1/status periodically. Manual refresh triggers immediate fetch.
class CombinedState {
  final Status? status;
  final StateData? state;
  CombinedState({this.status, this.state});
}

final statusProvider = FutureProvider<CombinedState>((ref) async {
  final api = ref.watch(apiProvider);
  if (api == null) return CombinedState();
  final results = await Future.wait([
    api.getStatus().catchError((_) => null as Status?),
    api.getState().catchError((_) => null as StateData?),
  ]);
  return CombinedState(
    status: results[0] as Status?,
    state: results[1] as StateData?,
  );
});
