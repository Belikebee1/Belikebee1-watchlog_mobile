import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../theme.dart';

/// Help & support hub: docs link, bug-report link, contact email,
/// source code link. Everything opens in the system browser / mail
/// client — keeps the in-app surface small while pointing users at
/// the canonical sources.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _docsUrl = 'https://watchlog.pl/';
  static const _issuesUrl = 'https://github.com/Belikebee1/watchlog/issues';
  static const _sourceUrl = 'https://github.com/Belikebee1/watchlog';
  static const _contactEmail = 'andrzej@belikebee.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, S.helpTitle))),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _LinkTile(
            icon: Icons.menu_book_outlined,
            title: tr(context, S.helpDocs),
            subtitle: tr(context, S.helpDocsHint),
            onTap: () => _launch(context, Uri.parse(_docsUrl)),
          ),
          _LinkTile(
            icon: Icons.bug_report_outlined,
            title: tr(context, S.helpReportBug),
            subtitle: tr(context, S.helpReportBugHint),
            onTap: () => _launch(context, Uri.parse(_issuesUrl)),
          ),
          _LinkTile(
            icon: Icons.mail_outline,
            title: tr(context, S.helpContactEmail),
            subtitle: tr(context, S.helpContactEmailHint),
            onTap: () => _launch(
              context,
              Uri(
                scheme: 'mailto',
                path: _contactEmail,
                queryParameters: {'subject': 'watchlog mobile feedback'},
              ),
            ),
          ),
          _LinkTile(
            icon: Icons.code,
            title: tr(context, S.helpSource),
            subtitle: tr(context, S.helpSourceHint),
            onTap: () => _launch(context, Uri.parse(_sourceUrl)),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uri.toString())),
      );
    }
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: context.surfaces.fgMuted, fontSize: 12),
      ),
      trailing: Icon(Icons.open_in_new,
          size: 18, color: context.surfaces.fgMuted),
      onTap: onTap,
    );
  }
}
