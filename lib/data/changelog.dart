/// Static release-notes catalogue, indexed by version string.
///
/// Each entry has bilingual `title` + `items` lists. Surfaces in two
/// places:
///   * "What's new" modal that pops automatically the first time the
///     user opens a build whose version is newer than what they saw
///     before.
///   * Settings → Release notes — full chronological scroll.
///
/// Adding a new version: prepend (newest first) so the modal and the
/// settings list show the latest at the top without having to sort.
const List<ChangelogEntry> kChangelog = [
  ChangelogEntry(
    version: '0.6.0',
    date: '2026-05-11',
    title: {
      'en': 'Mobile polish + power features',
      'pl': 'Polish UX + power features',
    },
    items: {
      'en': [
        'Multi-server overview as the home screen, with per-server detail behind a tap.',
        'Server detail header showing OS, kernel, uptime, IP, plus a tap-to-expand sheet with CPU/RAM/disk totals.',
        'Live disk + RAM bars on the status screen, colored by configured warn/critical thresholds.',
        'History browser: 90-day calendar of past runs, each day colored by worst severity. Drill in to per-run timelines.',
        'Action shortcuts: restart whitelisted services, view journalctl logs, optionally reboot — all with opt-in operator config.',
        'Per-server notification preferences: quiet hours, per-check muting, smart grouping cooldown to silence repeats.',
        'Custom snooze durations from 1 hour up to 1 week.',
        'Light / dark / system theme with smooth lerping between palettes.',
        'Full PL + EN localization across every screen.',
        'Humanized error messages with retry, diagnostics, and raw-error disclosure.',
        'Skeleton loaders replace spinners — pages stay stable while data loads.',
        'Biometric app lock (Face ID / fingerprint) with auto-lock + screenshot privacy.',
        'Encrypted backup/restore for the whole local state (AES-GCM, PBKDF2-600k).',
        'Audit log viewer with filter chips for actions / tokens / pairing events.',
        'Opt-in Crashlytics — off by default, anonymous when enabled.',
        'First-run onboarding tutorial; replayable from settings.',
      ],
      'pl': [
        'Multi-server overview jako home screen, szczegóły serwera za jednym tapem.',
        'Server detail header z OS, kernel, uptime, IP, plus rozwijalny arkusz z CPU/RAM/dysk total.',
        'Paski disk + RAM na żywo w status screen, kolorowane wg skonfigurowanych progów warn/critical.',
        'Przeglądarka historii: kalendarz 90 dni z każdym dniem pokolorowanym wg najgorszej severity. Drill-down do timeline\'u runów.',
        'Skróty akcji: restart whitelistowanych usług, podgląd logów journalctl, opcjonalnie reboot — wszystko z opt-in operatora.',
        'Preferencje powiadomień per serwer: ciche godziny, wyciszanie per check, smart grouping z cooldownem.',
        'Customowe długości snooze od 1 godziny do 1 tygodnia.',
        'Motyw jasny / ciemny / systemowy z płynnym lerping między paletami.',
        'Pełna lokalizacja PL + EN we wszystkich ekranach.',
        'Humanizowane błędy z retry, diagnostyką i ujawnieniem surowego błędu.',
        'Skeleton loadery zamiast spinerów — strony stabilne podczas ładowania.',
        'Biometryczny zamek aplikacji (Face ID / odcisk) z auto-lock + prywatnością screenshotów.',
        'Zaszyfrowana kopia zapasowa całego stanu (AES-GCM, PBKDF2-600k).',
        'Przeglądarka audit log z filtrami akcji / tokenów / pairingu.',
        'Opcjonalny Crashlytics — wyłączony domyślnie, anonimowy gdy włączony.',
        'Tutorial onboardingowy przy pierwszym uruchomieniu; do powtórzenia z Settings.',
      ],
    },
  ),
  ChangelogEntry(
    version: '0.5.0',
    date: '2026-05-09',
    title: {
      'en': 'Mobile foundation',
      'pl': 'Fundament mobilny',
    },
    items: {
      'en': [
        'First Android build: pairs to watchlog servers via QR codes.',
        'FCM push notifications with apply-security / snooze actions.',
        'Built-in check explainers in English and Polish.',
      ],
      'pl': [
        'Pierwszy build Androida: parowanie z serwerami watchlog przez kody QR.',
        'Powiadomienia FCM z akcjami apply-security / snooze.',
        'Wbudowane wyjaśnienia checków po polsku i angielsku.',
      ],
    },
  ),
];

class ChangelogEntry {
  final String version;
  final String date;
  final Map<String, String> title;
  final Map<String, List<String>> items;
  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.title,
    required this.items,
  });
}
