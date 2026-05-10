import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/models.dart';
import '../l10n/strings.dart';
import '../theme.dart';

class OutputScreen extends StatelessWidget {
  final String title;
  final ActionResult result;
  const OutputScreen({super.key, required this.title, required this.result});

  @override
  Widget build(BuildContext context) {
    final ok = result.ok;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: tr(context, S.copyOutputTooltip),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (ok ? AppColors.green : AppColors.red)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.error,
                    color: ok ? AppColors.green : AppColors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ok ? tr(context, S.successLabel) : tr(context, S.failedLabel),
                    style: TextStyle(
                      color: ok ? AppColors.green : AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                      tr(context, S.exitCode,
                          subs: {'n': '${result.exitCode}'}),
                      style: TextStyle(color: context.surfaces.fgMuted)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\$ ${result.command}',
              style: const TextStyle(
                color: AppColors.accent,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
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
                  child: SelectableText(
                    result.output.isEmpty
                        ? tr(context, S.noOutput)
                        : result.output,
                    style: TextStyle(
                      color: context.surfaces.fg,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
