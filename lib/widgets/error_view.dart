import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../utils/error_humanizer.dart';

/// Full-page error view used wherever a screen-level fetch fails.
///
/// Shows a humanized title + body + icon, a primary "Retry" button, and
/// an expandable "Show details" disclosure with the raw exception text
/// (so users can copy it into a bug report). When the underlying error
/// implies an actionable next step (re-pair, upgrade backend), the
/// caller can wire those buttons via [onSecondaryAction].
class ErrorView extends StatefulWidget {
  final HumanError error;
  final VoidCallback? onRetry;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;

  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.onSecondaryAction,
    this.secondaryActionLabel,
  });

  /// Convenience constructor: takes a raw exception, runs it through
  /// [humanize], and assembles the view.
  ErrorView.from(
    Object exception, {
    super.key,
    this.onRetry,
    this.onSecondaryAction,
    this.secondaryActionLabel,
  }) : error = humanize(exception);

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.red;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Container(
          width: 64,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 80),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.error.icon, color: color, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          widget.error.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.surfaces.fg,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.error.body,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.surfaces.fgMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        if (widget.onRetry != null)
          Center(
            child: ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            ),
          ),
        if (widget.onSecondaryAction != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: widget.onSecondaryAction,
              child: Text(widget.secondaryActionLabel ?? 'More options'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _showDetails = !_showDetails),
            icon: Icon(
              _showDetails ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: context.surfaces.fgMuted,
            ),
            label: Text(
              _showDetails ? 'Hide details' : 'Show details',
              style: TextStyle(color: context.surfaces.fgMuted),
            ),
          ),
        ),
        if (_showDetails) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaces.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.surfaces.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Raw error',
                      style: TextStyle(
                        color: context.surfaces.fgMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.error.rawDetails),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.copy,
                          size: 14,
                          color: context.surfaces.fgMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  widget.error.rawDetails,
                  style: TextStyle(
                    color: context.surfaces.fg,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
