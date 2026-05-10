import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../utils/error_humanizer.dart';
import '../widgets/error_view.dart';
import '../widgets/skeleton.dart';

/// Lightweight log viewer for one whitelisted service. Wraps
/// `POST /api/v1/actions/logs` and renders the resulting
/// journalctl tail. Pull-to-refresh re-fetches; the line count
/// dropdown lets the user grow / shrink the window. Read-only —
/// no edits possible from here, no log mutation API on the server.
class LogViewerScreen extends ConsumerStatefulWidget {
  final String serverId;
  final String service;
  const LogViewerScreen({
    super.key,
    required this.serverId,
    required this.service,
  });

  @override
  ConsumerState<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends ConsumerState<LogViewerScreen> {
  static const _lineOptions = [50, 100, 200, 500, 1000];
  int _lines = 100;
  Future<ActionResult>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<ActionResult> _fetch() async {
    final api = ref.read(serverApiProvider(widget.serverId));
    if (api == null) {
      throw StateError('Server not configured');
    }
    return api.tailLogs(widget.service, lines: _lines);
  }

  void _refresh() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, S.logsTitle, subs: {'service': widget.service})),
        actions: [
          IconButton(
            tooltip: tr(context, S.logsRefresh),
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          PopupMenuButton<int>(
            tooltip: tr(context, S.logsLines, subs: {'n': '$_lines'}),
            initialValue: _lines,
            icon: const Icon(Icons.format_list_numbered),
            onSelected: (v) {
              setState(() {
                _lines = v;
                _future = _fetch();
              });
            },
            itemBuilder: (ctx) => [
              for (final n in _lineOptions)
                PopupMenuItem<int>(
                  value: n,
                  child: Text(tr(ctx, S.logsLines, subs: {'n': '$n'})),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh();
          // Tiny pause so the spinner shows even on instant local
          // round-trips — feels more responsive than instant snap.
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
        child: FutureBuilder<ActionResult>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _LogSkeleton();
            }
            if (snap.hasError) {
              return ErrorView.from(
                snap.error!,
                onRetry: _refresh,
              );
            }
            final result = snap.data!;
            return _LogBody(result: result);
          },
        ),
      ),
    );
  }
}

class _LogBody extends StatelessWidget {
  final ActionResult result;
  const _LogBody({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '\$ ${result.command}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                tooltip: tr(context, S.copyOutputTooltip),
                icon: const Icon(Icons.copy_outlined, size: 18),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: result.output));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr(context, S.copyToClipboard))),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaces.codeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.surfaces.border),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: SelectableText(
                  result.output.isEmpty ? tr(context, S.noOutput) : result.output,
                  style: TextStyle(
                    color: context.surfaces.fg,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogSkeleton extends StatelessWidget {
  const _LogSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonGroup(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Skeleton(width: 200, height: 12),
            SizedBox(height: 12),
            Expanded(child: Skeleton(radius: 8)),
          ],
        ),
      ),
    );
  }
}
