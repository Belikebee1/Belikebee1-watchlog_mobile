import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart';

/// Centralized UI string catalogue, indexed by message key and language.
///
/// Why not Flutter's official `gen-l10n` / ARB workflow:
///   * we already use the same `{en: ..., pl: ...}` shape on the backend
///     for check explainers and severity legend — keeping mobile and
///     backend on the same idiom means one mental model
///   * no codegen step in the build pipeline; pulling and running
///     `flutter pub get` is enough to ship a translation
///   * adding a third language is a one-key edit; the runtime fallback
///     to `en` keeps unsupported locales working immediately
///
/// Lookup helper: [tr(context, S.someKey)] resolves the user's chosen
/// app locale (or system default) and falls back to English.
class S {
  // ----- Common buttons / actions -----
  static const cancel = {'en': 'Cancel', 'pl': 'Anuluj'};
  static const save = {'en': 'Save', 'pl': 'Zapisz'};
  static const tryAgain = {'en': 'Try again', 'pl': 'Spróbuj ponownie'};
  static const showDetails = {'en': 'Show details', 'pl': 'Pokaż szczegóły'};
  static const hideDetails = {'en': 'Hide details', 'pl': 'Ukryj szczegóły'};
  static const moreOptions = {'en': 'More options', 'pl': 'Więcej opcji'};
  static const openSettings = {'en': 'Open settings', 'pl': 'Otwórz ustawienia'};
  static const copyToClipboard = {
    'en': 'Copied to clipboard',
    'pl': 'Skopiowano do schowka',
  };
  static const refreshTooltip = {'en': 'Refresh', 'pl': 'Odśwież'};

  // ----- Navigation / screens -----
  static const settingsTitle = {'en': 'Settings', 'pl': 'Ustawienia'};
  static const watchlogBrand = {'en': '👁️  watchlog', 'pl': '👁️  watchlog'};

  // ----- Overview screen -----
  static const noServersYet = {
    'en': 'No servers yet',
    'pl': 'Brak serwerów',
  };
  static const noServersHint = {
    'en': 'Pair your first watchlog server to see its health here.',
    'pl': 'Sparuj pierwszy serwer watchlog żeby zobaczyć tu jego stan.',
  };
  static const pairServerCta = {
    'en': 'Pair server',
    'pl': 'Sparuj serwer',
  };
  static const addServerFab = {'en': 'Add server', 'pl': 'Dodaj serwer'};
  static const addServerTitle = {'en': 'Add server', 'pl': 'Dodaj serwer'};
  static const addServerEllipsis = {
    'en': 'Add server…',
    'pl': 'Dodaj serwer…',
  };
  static const summaryAllPassing = {
    'en': 'All checks passing',
    'pl': 'Wszystkie sprawdzenia OK',
  };
  static const summaryCriticalFix = {
    'en': 'CRITICAL · {n} to fix',
    'pl': 'KRYTYCZNE · {n} do naprawy',
  };
  static const summaryWarnLook = {
    'en': 'WARN · {n} to look at',
    'pl': 'OSTRZEŻENIE · {n} do sprawdzenia',
  };
  static const summaryInfoAdvisory = {
    'en': 'INFO · {n} advisory',
    'pl': 'INFO · {n} wskazówka',
  };
  static const ageJustNow = {'en': 'just now', 'pl': 'przed chwilą'};
  static const ageMinutesAgo = {'en': '{n}m ago', 'pl': '{n}m temu'};
  static const ageHoursAgo = {'en': '{n}h ago', 'pl': '{n}h temu'};
  static const ageDaysAgo = {'en': '{n}d ago', 'pl': '{n}d temu'};

  // ----- Status screen -----
  static const tabStatus = {'en': 'Status', 'pl': 'Status'};
  static const tabChecks = {'en': 'Checks', 'pl': 'Sprawdzenia'};
  static const tabActions = {'en': 'Actions', 'pl': 'Akcje'};
  static const applySecurityBtn = {
    'en': 'Apply security',
    'pl': 'Zaktualizuj bezpieczeństwo',
  };
  static const runNowBtn = {'en': 'Run now', 'pl': 'Uruchom teraz'};
  static const applySecurityConfirmTitle = {
    'en': 'Apply security updates?',
    'pl': 'Zaktualizować pakiety bezpieczeństwa?',
  };
  static const applySecurityConfirmBody = {
    'en':
        'This will run `unattended-upgrade -v` on the server. It may install patches and (rarely) require a service restart.',
    'pl':
        'Uruchomi `unattended-upgrade -v` na serwerze. Może zainstalować poprawki i (rzadko) wymagać restartu usług.',
  };
  static const applySecurityCta = {'en': 'Apply', 'pl': 'Zastosuj'};
  static const runningWatchlog = {
    'en': 'Running watchlog…',
    'pl': 'Uruchamiam watchlog…',
  };
  static const applyingSecurity = {
    'en': 'Applying security updates…',
    'pl': 'Aplikuję aktualizacje bezpieczeństwa…',
  };
  static const watchlogRunTitle = {'en': 'watchlog run', 'pl': 'watchlog run'};
  static const applySecurityTitle = {
    'en': 'Apply security updates',
    'pl': 'Aktualizacja bezpieczeństwa',
  };
  static const allChecksPassing = {
    'en': 'All checks passing.',
    'pl': 'Wszystkie sprawdzenia przechodzą.',
  };
  static const nothingToActOn = {
    'en': 'Nothing to act on.',
    'pl': 'Nic nie wymaga reakcji.',
  };
  static const snackSnoozed = {
    'en': 'Snoozed {check} for 4h',
    'pl': 'Wyciszono {check} na 4h',
  };
  static const snackIgnored = {
    'en': 'Ignored {check}',
    'pl': 'Zignorowano {check}',
  };
  static const snackCleared = {
    'en': 'Cleared {check}',
    'pl': 'Wyczyszczono {check}',
  };

  // ----- Severity banner -----
  static const noHeartbeat = {
    'en': 'No heartbeat yet',
    'pl': 'Brak danych z serwera',
  };
  static const noHeartbeatHint = {
    'en': 'Run watchlog at least once on the server.',
    'pl': 'Uruchom watchlog przynajmniej raz na serwerze.',
  };
  static const allClearN = {
    'en': 'All clear – {n} checks',
    'pl': 'Wszystko OK – {n} sprawdzeń',
  };
  static const itemsNeedAttention = {
    'en': '{n} item(s) need attention',
    'pl': '{n} pozycji do sprawdzenia',
  };
  static const ageMinAgo = {'en': '{n} min ago', 'pl': '{n} min temu'};
  static const ageHAgo = {'en': '{n} h ago', 'pl': '{n} h temu'};

  // ----- Check actions / explainer -----
  static const snooze4h = {'en': 'Snooze 4h', 'pl': 'Wycisz na 4h'};
  static const snoozeShort = {'en': 'Snooze', 'pl': 'Wycisz'};
  static const snoozePickerTitle = {
    'en': 'Snooze {check}',
    'pl': 'Wycisz {check}',
  };
  static const snoozePickerHint = {
    'en':
        'Pick how long to silence this check across email, Telegram, and push.',
    'pl':
        'Wybierz na jak długo wyciszyć ten check — działa dla email, Telegramu i pusha.',
  };
  static const snooze1h = {'en': '1 hour', 'pl': '1 godzina'};
  static const snooze4hLabel = {'en': '4 hours', 'pl': '4 godziny'};
  static const snooze12h = {'en': '12 hours', 'pl': '12 godzin'};
  static const snooze24h = {'en': '1 day', 'pl': '1 dzień'};
  static const snooze72h = {'en': '3 days', 'pl': '3 dni'};
  static const snooze168h = {'en': '1 week', 'pl': '1 tydzień'};
  static const snoozeCustom = {'en': 'Custom…', 'pl': 'Inny…'};
  static const snoozeCustomTitle = {
    'en': 'Custom snooze duration',
    'pl': 'Niestandardowy czas wyciszenia',
  };
  static const snoozeCustomLabel = {
    'en': 'Hours (1 to 720)',
    'pl': 'Godziny (1 do 720)',
  };
  static const snoozeSnackHours = {
    'en': 'Snoozed {check} for {n}h',
    'pl': 'Wyciszono {check} na {n}h',
  };
  static const snoozeSnackDays = {
    'en': 'Snoozed {check} for {n} days',
    'pl': 'Wyciszono {check} na {n} dni',
  };
  static const ignore = {'en': 'Ignore', 'pl': 'Ignoruj'};
  static const clear = {'en': 'Clear', 'pl': 'Wyczyść'};
  static const reEnable = {'en': 'Re-enable', 'pl': 'Włącz ponownie'};
  static const snoozedBadge = {'en': 'snoozed', 'pl': 'wyciszone'};
  static const ignoredBadge = {'en': 'ignored', 'pl': 'ignorowane'};
  static const snoozedRow = {'en': '(snoozed)', 'pl': '(wyciszone)'};
  static const ignoredRow = {'en': '(ignored)', 'pl': '(ignorowane)'};
  static const whatItChecks = {
    'en': 'What it checks',
    'pl': 'Co sprawdza',
  };
  static const whyItMatters = {
    'en': 'Why it matters',
    'pl': 'Dlaczego to ważne',
  };
  static const rightNow = {'en': 'Right now', 'pl': 'Aktualnie'};
  static const howToFix = {'en': 'How to fix', 'pl': 'Co zrobić'};

  // ----- Severity legend -----
  static const severityLevels = {
    'en': 'Severity levels',
    'pl': 'Poziomy ważności',
  };

  // ----- Settings -----
  static const sectionServers = {'en': 'Servers', 'pl': 'Serwery'};
  static const sectionAppearance = {'en': 'Appearance', 'pl': 'Wygląd'};
  static const sectionLanguage = {'en': 'Language', 'pl': 'Język'};
  static const sectionAbout = {'en': 'About', 'pl': 'O aplikacji'};
  static const aboutBody = {
    'en': 'watchlog mobile · v0.1.0\nhttps://watchlog.pl',
    'pl': 'watchlog mobile · v0.1.0\nhttps://watchlog.pl',
  };
  static const themeLabel = {'en': 'Theme', 'pl': 'Motyw'};
  static const themeSystem = {'en': 'System', 'pl': 'Systemowy'};
  static const themeLight = {'en': 'Light', 'pl': 'Jasny'};
  static const themeDark = {'en': 'Dark', 'pl': 'Ciemny'};
  static const langSystem = {'en': 'System', 'pl': 'Systemowy'};
  static const langEnglish = {'en': 'English', 'pl': 'English'};
  static const langPolish = {'en': 'Polski', 'pl': 'Polski'};
  static const renameServer = {
    'en': 'Rename server',
    'pl': 'Zmień nazwę serwera',
  };
  static const displayName = {
    'en': 'Display name',
    'pl': 'Nazwa wyświetlana',
  };
  static const renameMenu = {'en': 'Rename', 'pl': 'Zmień nazwę'};
  static const removeMenu = {'en': 'Remove', 'pl': 'Usuń'};
  static const removeServerTitle = {
    'en': 'Remove {name}?',
    'pl': 'Usunąć {name}?',
  };
  static const removeServerBody = {
    'en': 'This stops alerts from this server on this device.',
    'pl': 'Powiadomienia z tego serwera przestaną przychodzić na to urządzenie.',
  };
  static const signOutAll = {
    'en': 'Sign out of all servers',
    'pl': 'Wyloguj ze wszystkich serwerów',
  };
  static const signOutAllConfirmTitle = {
    'en': 'Sign out of all servers?',
    'pl': 'Wylogować ze wszystkich serwerów?',
  };
  static const signOutAllConfirmBody = {
    'en':
        'This removes every server from this device. You will need to add them again to receive alerts.',
    'pl':
        'Usuwa każdy serwer z tego urządzenia. Trzeba je dodać ponownie żeby dostawać powiadomienia.',
  };
  static const signOutCta = {'en': 'Sign out', 'pl': 'Wyloguj'};

  // ----- Add server / pair flow -----
  static const watchlogTitle = {'en': 'watchlog', 'pl': 'watchlog'};
  static const addFirstServer = {
    'en': 'Add your first watchlog server.',
    'pl': 'Dodaj swój pierwszy serwer watchlog.',
  };
  static const scanQrBtn = {
    'en': 'Scan QR code',
    'pl': 'Skanuj kod QR',
  };
  static const onServerRunQr = {
    'en': 'On the server run:  sudo watchlog api qr',
    'pl': 'Na serwerze uruchom:  sudo watchlog api qr',
  };
  static const orDivider = {'en': 'OR', 'pl': 'LUB'};
  static const setupManually = {
    'en': 'Set up manually (advanced)',
    'pl': 'Skonfiguruj ręcznie (zaawansowane)',
  };
  static const displayNameOptional = {
    'en': 'Display name (optional)',
    'pl': 'Nazwa wyświetlana (opcjonalnie)',
  };
  static const apiBaseUrl = {
    'en': 'API base URL',
    'pl': 'Adres API serwera',
  };
  static const bearerToken = {
    'en': 'Bearer token',
    'pl': 'Token Bearer',
  };
  static const pasteToken = {
    'en': 'paste token',
    'pl': 'wklej token',
  };
  static const urlAndTokenRequired = {
    'en': 'URL and token are required.',
    'pl': 'URL i token są wymagane.',
  };
  static const invalidToken = {
    'en': 'Invalid token.',
    'pl': 'Niepoprawny token.',
  };
  static const networkErrorPrefix = {
    'en': 'Network error: {detail}',
    'pl': 'Błąd sieci: {detail}',
  };
  static const errorPrefix = {'en': 'Error: {detail}', 'pl': 'Błąd: {detail}'};

  // ----- Pair screen -----
  static const scanPairingQr = {
    'en': 'Scan pairing QR',
    'pl': 'Skanuj QR pairingu',
  };
  static const enterCodeManually = {
    'en': 'Enter code manually',
    'pl': 'Wpisz kod ręcznie',
  };
  static const useCameraScanner = {
    'en': 'Use camera scanner',
    'pl': 'Użyj skanera kamery',
  };
  static const toggleTorch = {
    'en': 'Toggle torch',
    'pl': 'Przełącz latarkę',
  };
  static const invalidCode = {
    'en': 'Invalid, expired, or already-used code.',
    'pl': 'Niepoprawny, wygasły lub już użyty kod.',
  };
  static const serverUrlAndCodeRequired = {
    'en': 'Server URL and code are required.',
    'pl': 'Adres serwera i kod są wymagane.',
  };
  static const serverUrl = {'en': 'Server URL', 'pl': 'Adres serwera'};
  static const pairingCode = {'en': 'Pairing code', 'pl': 'Kod pairingu'};
  static const runOnServerMultiline = {
    'en': 'Run on the server:\nsudo watchlog api qr',
    'pl': 'Uruchom na serwerze:\nsudo watchlog api qr',
  };
  static const pairBtn = {'en': 'Pair', 'pl': 'Sparuj'};
  static const cameraPermissionDenied = {
    'en':
        'Camera permission denied. Grant camera access in Settings or pair with a typed code instead.',
    'pl':
        'Brak uprawnienia do kamery. Przyznaj dostęp w ustawieniach lub sparuj wpisując kod ręcznie.',
  };
  static const scannerUnsupported = {
    'en': "This device doesn't support QR scanning. Use the manual code entry.",
    'pl':
        'To urządzenie nie obsługuje skanowania QR. Użyj ręcznego wpisania kodu.',
  };
  static const cameraError = {
    'en': 'Camera error: {detail}',
    'pl': 'Błąd kamery: {detail}',
  };

  // ----- Server header / host info sheet -----
  static const upPrefix = {'en': 'up {duration}', 'pl': 'działa {duration}'};
  static const operatingSystem = {
    'en': 'Operating system',
    'pl': 'System operacyjny',
  };
  static const kernel = {'en': 'Kernel', 'pl': 'Jądro (kernel)'};
  static const architecture = {'en': 'Architecture', 'pl': 'Architektura'};
  static const cpuLabel = {'en': 'CPU', 'pl': 'Procesor'};
  static const ramLabel = {'en': 'RAM', 'pl': 'Pamięć RAM'};
  static const diskTotalRoot = {
    'en': 'Disk total (/)',
    'pl': 'Dysk razem (/)',
  };
  static const uptime = {'en': 'Uptime', 'pl': 'Czas działania'};
  static const booted = {'en': 'Booted', 'pl': 'Uruchomiony'};
  static const timezone = {'en': 'Timezone', 'pl': 'Strefa czasowa'};
  static const networkSection = {'en': 'NETWORK', 'pl': 'SIEĆ'};
  static const cores = {'en': 'core', 'pl': 'rdzeń'};
  static const coresPlural = {'en': 'cores', 'pl': 'rdzenie'};

  // ----- Output screen -----
  static const successLabel = {'en': 'Success', 'pl': 'Sukces'};
  static const failedLabel = {'en': 'Failed', 'pl': 'Błąd'};
  static const exitCode = {'en': 'exit {n}', 'pl': 'kod wyjścia {n}'};
  static const noOutput = {'en': '(no output)', 'pl': '(brak wyniku)'};
  static const copyOutputTooltip = {
    'en': 'Copy output',
    'pl': 'Skopiuj wynik',
  };

  // ----- Action shortcuts (Phase 2D) -----
  static const sectionActions = {'en': 'Actions', 'pl': 'Akcje'};
  static const restartPrefix = {
    'en': 'Restart {service}',
    'pl': 'Zrestartuj {service}',
  };
  static const logsPrefix = {
    'en': 'Logs: {service}',
    'pl': 'Logi: {service}',
  };
  static const rebootServer = {
    'en': 'Reboot server',
    'pl': 'Zrestartuj serwer',
  };
  static const restartConfirmTitle = {
    'en': 'Restart {service}?',
    'pl': 'Zrestartować {service}?',
  };
  static const restartConfirmBody = {
    'en':
        'systemctl restart {service} will run on the server. Active connections to this service may drop briefly.',
    'pl':
        'systemctl restart {service} uruchomi się na serwerze. Aktywne połączenia mogą się na chwilę przerwać.',
  };
  static const restartCta = {'en': 'Restart', 'pl': 'Restart'};
  static const rebootConfirmTitle = {
    'en': 'Reboot server?',
    'pl': 'Zrestartować serwer?',
  };
  static const rebootConfirmBody = {
    'en':
        'The server reboots in 1 minute. ALL services go down. Run `shutdown -c` on the box within that minute to abort.',
    'pl':
        'Serwer zrestartuje się za 1 minutę. WSZYSTKIE usługi się wyłączą. Uruchom `shutdown -c` na serwerze w tym czasie, by anulować.',
  };
  static const rebootCta = {'en': 'Reboot', 'pl': 'Restart'};
  static const restartingSnack = {
    'en': 'Restarting {service}…',
    'pl': 'Restartuję {service}…',
  };
  static const reboootingSnack = {
    'en': 'Reboot scheduled in 1 minute',
    'pl': 'Restart zaplanowany za 1 minutę',
  };
  static const noActionsConfigured = {
    'en':
        'No action shortcuts configured. Edit /etc/watchlog/config.yaml on the server and add services to actions.allowed_services.',
    'pl':
        'Brak skonfigurowanych akcji. Edytuj /etc/watchlog/config.yaml na serwerze i dodaj usługi do actions.allowed_services.',
  };
  static const logsTitle = {
    'en': 'Logs: {service}',
    'pl': 'Logi: {service}',
  };
  static const logsLines = {
    'en': 'Last {n} lines',
    'pl': 'Ostatnie {n} linii',
  };
  static const logsRefresh = {'en': 'Refresh', 'pl': 'Odśwież'};

  // ----- History browser (Phase 2C) -----
  static const historyTitle = {'en': 'History', 'pl': 'Historia'};
  static const historyTooltip = {
    'en': 'Open history',
    'pl': 'Otwórz historię',
  };
  static const noHistory = {
    'en': 'No archived runs yet',
    'pl': 'Brak zarchiwizowanych uruchomień',
  };
  static const noHistoryHint = {
    'en':
        'Once watchlog has run a few times the daily archives will show up here.',
    'pl':
        'Gdy watchlog zrobi kilka uruchomień, dzienne archiwa pojawią się tutaj.',
  };
  static const runsCount = {'en': '{n} runs', 'pl': '{n} uruchomień'};
  static const runsCountSingular = {
    'en': '{n} run',
    'pl': '{n} uruchomienie',
  };
  static const dayDetailTitle = {'en': '{date}', 'pl': '{date}'};
  static const noRunsForDay = {
    'en': 'No runs recorded for this day',
    'pl': 'Brak uruchomień zapisanych na ten dzień',
  };

  // ----- Audit log (Phase 3Q) -----
  static const auditMenu = {'en': 'Audit log…', 'pl': 'Dziennik akcji…'};
  static const auditTitle = {'en': 'Audit log', 'pl': 'Dziennik akcji'};
  static const auditEmpty = {
    'en': 'No events yet',
    'pl': 'Brak zdarzeń',
  };
  static const auditEmptyHint = {
    'en':
        'Pairing, restart, snooze, and similar actions show up here in real time.',
    'pl':
        'Pairing, restart, snooze i podobne akcje pojawiają się tu na żywo.',
  };
  static const auditFilterAll = {'en': 'All', 'pl': 'Wszystko'};
  static const auditFilterActions = {'en': 'Actions', 'pl': 'Akcje'};
  static const auditFilterTokens = {'en': 'Tokens', 'pl': 'Tokeny'};
  static const auditFilterPairing = {'en': 'Pairing', 'pl': 'Pairing'};

  // Friendly labels — fall back to the raw event name when missing.
  // Keep these short; details still render in the subtitle.
  static const evtActionRestartService = {
    'en': 'Restarted {service}',
    'pl': 'Zrestartowano {service}',
  };
  static const evtActionRestartDenied = {
    'en': 'Restart denied: {service}',
    'pl': 'Restart odmówiony: {service}',
  };
  static const evtActionReboot = {
    'en': 'Server reboot scheduled',
    'pl': 'Zaplanowano restart serwera',
  };
  static const evtActionRebootDenied = {
    'en': 'Reboot denied',
    'pl': 'Restart odmówiony',
  };
  static const evtActionApplySecurity = {
    'en': 'Applied security updates',
    'pl': 'Zaaplikowano aktualizacje bezpieczeństwa',
  };
  static const evtActionTailLogs = {
    'en': 'Viewed logs: {service}',
    'pl': 'Wyświetlono logi: {service}',
  };
  static const evtActionLogsDenied = {
    'en': 'Logs denied: {service}',
    'pl': 'Logi odmówione: {service}',
  };
  static const evtTokenIssued = {
    'en': 'Token issued ({device})',
    'pl': 'Wystawiono token ({device})',
  };
  static const evtTokenRevoked = {
    'en': 'Token revoked',
    'pl': 'Odwołano token',
  };
  static const evtTokenAuthFailed = {
    'en': 'Auth attempt failed',
    'pl': 'Nieudana próba autoryzacji',
  };
  static const evtTokenForbidden = {
    'en': 'Permission denied',
    'pl': 'Brak uprawnień',
  };
  static const evtTokenPrefsUpdated = {
    'en': 'Notification settings updated',
    'pl': 'Zaktualizowano ustawienia powiadomień',
  };
  static const evtPairGenerated = {
    'en': 'Pairing code generated',
    'pl': 'Wygenerowano kod pairingu',
  };
  static const evtPairRedeemed = {
    'en': 'Device paired',
    'pl': 'Urządzenie sparowane',
  };
  static const evtPairFailed = {
    'en': 'Pairing failed: {reason}',
    'pl': 'Pairing nieudany: {reason}',
  };
  static const evtPairLockedOut = {
    'en': 'Pairing code locked out',
    'pl': 'Kod pairingu zablokowany',
  };

  // ----- Changelog (Phase 4J) -----
  static const releaseNotesTitle = {
    'en': 'Release notes',
    'pl': 'Notatki wydań',
  };
  static const releaseNotesMenu = {
    'en': 'Release notes',
    'pl': 'Notatki wydań',
  };
  static const whatsNewTitle = {
    'en': "What's new in {version}",
    'pl': 'Co nowego w {version}',
  };
  static const whatsNewClose = {'en': 'Got it', 'pl': 'Rozumiem'};
  static const versionLabel = {'en': 'Version {n}', 'pl': 'Wersja {n}'};

  // ----- Help / support (Phase 5U) -----
  static const sectionHelp = {'en': 'Help', 'pl': 'Pomoc'};
  static const helpTitle = {'en': 'Help & support', 'pl': 'Pomoc i wsparcie'};
  static const helpMenu = {'en': 'Help & support', 'pl': 'Pomoc i wsparcie'};
  static const helpDocs = {
    'en': 'Documentation',
    'pl': 'Dokumentacja',
  };
  static const helpDocsHint = {
    'en': 'Setup guides, check explainers, and the API reference on watchlog.pl.',
    'pl': 'Przewodniki konfiguracji, wyjaśnienia checków i referencja API na watchlog.pl.',
  };
  static const helpReportBug = {
    'en': 'Report a bug',
    'pl': 'Zgłoś błąd',
  };
  static const helpReportBugHint = {
    'en': 'Opens GitHub issues for the watchlog repo.',
    'pl': 'Otwiera GitHub issues dla repo watchlog.',
  };
  static const helpContactEmail = {
    'en': 'Contact email',
    'pl': 'Kontakt mailowy',
  };
  static const helpContactEmailHint = {
    'en': 'andrzej@belikebee.com — reach the maintainer directly.',
    'pl': 'andrzej@belikebee.com — bezpośredni kontakt z autorem.',
  };
  static const helpSource = {
    'en': 'Source code',
    'pl': 'Kod źródłowy',
  };
  static const helpSourceHint = {
    'en': 'Backend on GitHub Belikebee1/watchlog (MIT licensed).',
    'pl': 'Backend na GitHubie Belikebee1/watchlog (licencja MIT).',
  };

  // ----- Analytics (Phase 5T) -----
  static const analyticsTitle = {
    'en': 'Anonymous usage stats',
    'pl': 'Anonimowe statystyki użycia',
  };
  static const analyticsHint = {
    'en':
        'Helps me see which features are actually used. No tokens, hostnames, or personal data ever leave the device. Off by default.',
    'pl':
        'Pomaga mi widzieć, które funkcje są używane. Tokeny, hostnames ani inne dane osobowe nie opuszczają urządzenia. Domyślnie wyłączone.',
  };

  // ----- Onboarding (Phase 4I) -----
  static const onboardingReplay = {
    'en': 'Show onboarding again',
    'pl': 'Pokaż wprowadzenie ponownie',
  };
  static const onboardingNext = {'en': 'Next', 'pl': 'Dalej'};
  static const onboardingSkip = {'en': 'Skip', 'pl': 'Pomiń'};
  static const onboardingGetStarted = {
    'en': 'Get started',
    'pl': 'Zaczynamy',
  };
  static const ob1Title = {
    'en': 'Welcome to watchlog',
    'pl': 'Witaj w watchlog',
  };
  static const ob1Body = {
    'en':
        'Daily health & security checks for your Linux servers, with mobile alerts when something needs attention.',
    'pl':
        'Codzienne sprawdzenia zdrowia i bezpieczeństwa Twoich serwerów Linux, z powiadomieniami mobilnymi gdy coś wymaga uwagi.',
  };
  static const ob2Title = {
    'en': 'Pair in seconds',
    'pl': 'Sparuj w sekundach',
  };
  static const ob2Body = {
    'en':
        'Run sudo watchlog api qr on the server, point your phone at the terminal, done. No copy-paste of bearer tokens. Each device gets its own revocable token.',
    'pl':
        'Uruchom sudo watchlog api qr na serwerze, skieruj telefon na terminal, gotowe. Bez kopiowania bearer tokenów. Każde urządzenie dostaje własny, odwoływalny token.',
  };
  static const ob3Title = {
    'en': 'Smart notifications',
    'pl': 'Inteligentne powiadomienia',
  };
  static const ob3Body = {
    'en':
        'Push when something fires, silenced during your quiet hours, grouped so the same warning never spams you. Apply security updates straight from the alert.',
    'pl':
        'Push gdy coś się stanie, wyciszony w cichych godzinach, grupowany żeby to samo ostrzeżenie nie spamowało. Aplikuj security updates prosto z alertu.',
  };
  static const ob4Title = {
    'en': 'Your data, your phone',
    'pl': 'Twoje dane, Twój telefon',
  };
  static const ob4Body = {
    'en':
        'Tokens live in the OS keystore. Optional biometric lock. Encrypted backup to move between phones. Crash reports are opt-in — nothing leaves the device until you flip the switch.',
    'pl':
        'Tokeny mieszkają w systemowym keystore. Opcjonalny zamek biometryczny. Zaszyfrowana kopia zapasowa do przenoszenia między telefonami. Raporty błędów są opt-in — nic nie opuszcza urządzenia dopóki nie włączysz.',
  };

  // ----- Crash reporting (Phase 3S) -----
  static const crashReportingTitle = {
    'en': 'Send crash reports',
    'pl': 'Wysyłaj raporty błędów',
  };
  static const crashReportingHint = {
    'en':
        'Anonymous crash logs + stack traces help fix bugs faster. Nothing else is collected. Off by default.',
    'pl':
        'Anonimowe raporty awarii + stack trace pomagają szybciej naprawiać bugi. Nic innego nie jest zbierane. Domyślnie wyłączone.',
  };

  // ----- Backup / restore (Phase 3P) -----
  static const sectionData = {'en': 'Data', 'pl': 'Dane'};
  static const dataTitle = {
    'en': 'Backup & restore',
    'pl': 'Kopia zapasowa i odtworzenie',
  };
  static const dataMenu = {
    'en': 'Backup & restore…',
    'pl': 'Kopia i odtworzenie…',
  };
  static const dataHint = {
    'en':
        'Export your server list, tokens, and preferences to an encrypted file you can save to cloud storage or another phone. Restoring replaces the current state — pair tokens stay valid since the server identifies devices by token, not phone.',
    'pl':
        'Eksportuj listę serwerów, tokeny i ustawienia do zaszyfrowanego pliku, który możesz zapisać w chmurze lub na innym telefonie. Odtworzenie zastępuje aktualny stan — tokeny pozostają ważne, bo serwer identyfikuje urządzenia po tokenie, nie po telefonie.',
  };
  static const exportCta = {
    'en': 'Export backup…',
    'pl': 'Eksportuj kopię…',
  };
  static const importCta = {
    'en': 'Import backup…',
    'pl': 'Importuj kopię…',
  };
  static const exportEmpty = {
    'en': 'No servers configured — nothing to export.',
    'pl': 'Brak skonfigurowanych serwerów — nic do eksportu.',
  };
  static const exportPassphraseTitle = {
    'en': 'Encrypt backup',
    'pl': 'Zaszyfruj kopię',
  };
  static const exportPassphraseHint = {
    'en':
        'Pick a passphrase. You\'ll need this exact phrase to restore — write it down.',
    'pl':
        'Wybierz hasło. Będzie potrzebne dokładnie to samo hasło żeby odtworzyć — zapisz je.',
  };
  static const importPassphraseTitle = {
    'en': 'Decrypt backup',
    'pl': 'Odszyfruj kopię',
  };
  static const importPassphraseHint = {
    'en': 'Enter the passphrase the backup was created with.',
    'pl': 'Wprowadź hasło, którym kopia była zaszyfrowana.',
  };
  static const passphraseLabel = {
    'en': 'Passphrase (min 8 chars)',
    'pl': 'Hasło (min 8 znaków)',
  };
  static const passphraseRepeat = {
    'en': 'Repeat passphrase',
    'pl': 'Powtórz hasło',
  };
  static const passphraseTooShort = {
    'en': 'Use at least 8 characters',
    'pl': 'Użyj minimum 8 znaków',
  };
  static const passphraseMismatch = {
    'en': 'Passphrases don\'t match',
    'pl': 'Hasła nie pasują',
  };
  static const wrongPassphrase = {
    'en': 'Wrong passphrase or corrupted file',
    'pl': 'Niepoprawne hasło lub uszkodzony plik',
  };
  static const restoreConfirmTitle = {
    'en': 'Restore from backup?',
    'pl': 'Odtworzyć z kopii?',
  };
  static const restoreConfirmBody = {
    'en':
        'Imports {n} server(s) from {ts}. Your current server list will be replaced. Continue?',
    'pl':
        'Importuje {n} serwer(ów) z {ts}. Twoja aktualna lista zostanie zastąpiona. Kontynuować?',
  };
  static const restoreApply = {'en': 'Restore', 'pl': 'Odtwórz'};
  static const restoreApplied = {
    'en': 'Backup applied',
    'pl': 'Kopia odtworzona',
  };

  // ----- App lock (Phase 3O) -----
  static const sectionSecurity = {
    'en': 'Security',
    'pl': 'Bezpieczeństwo',
  };
  static const biometricToggle = {
    'en': 'Require biometric on launch',
    'pl': 'Wymagaj biometrii przy starcie',
  };
  static const biometricHint = {
    'en':
        'Use Face ID / fingerprint / device PIN to unlock the app. Server tokens stay encrypted in the system keystore regardless of this setting.',
    'pl':
        'Użyj Face ID / odcisku palca / PIN-u urządzenia żeby odblokować aplikację. Tokeny serwerów są zaszyfrowane w systemowym keystore niezależnie od tej opcji.',
  };
  static const biometricUnavailable = {
    'en': 'No biometric enrolled on this device',
    'pl': 'Brak skonfigurowanej biometrii na tym urządzeniu',
  };
  static const autoLockLabel = {
    'en': 'Auto-lock after',
    'pl': 'Automatyczny zamek po',
  };
  static const autoLockImmediate = {'en': 'Immediately', 'pl': 'Natychmiast'};
  static const autoLockMinutes = {'en': '{n} min', 'pl': '{n} min'};
  static const autoLockNever = {'en': 'Never (session only)', 'pl': 'Nigdy (tylko sesja)'};
  static const secureScreenToggle = {
    'en': 'Hide app from screenshots',
    'pl': 'Ukryj aplikację przed screenshotami',
  };
  static const secureScreenHint = {
    'en':
        'Prevents the OS task switcher and screenshot APIs from capturing watchlog content. Android only for now.',
    'pl':
        'Zapobiega przechwytywaniu zawartości watchlog przez task switcher i screenshoty. Na razie tylko Android.',
  };
  static const lockTitle = {
    'en': 'watchlog locked',
    'pl': 'watchlog zablokowany',
  };
  static const lockSubtitle = {
    'en': 'Authenticate to unlock the dashboard.',
    'pl': 'Uwierzytelnij się żeby odblokować dashboard.',
  };
  static const lockReason = {
    'en': 'Unlock watchlog',
    'pl': 'Odblokuj watchlog',
  };
  static const lockAuthenticate = {
    'en': 'Authenticate',
    'pl': 'Uwierzytelnij',
  };
  static const lockFailed = {
    'en': 'Authentication failed',
    'pl': 'Uwierzytelnianie nieudane',
  };

  // ----- Live metrics (disk / memory tile) -----
  static const liveMetricsHeader = {
    'en': 'LIVE',
    'pl': 'NA ŻYWO',
  };
  static const diskLabel = {'en': 'Disk', 'pl': 'Dysk'};
  static const ramLabel2 = {'en': 'RAM', 'pl': 'RAM'};
  static const usedShort = {'en': 'used', 'pl': 'zajęte'};
  static const freeShort = {'en': 'free', 'pl': 'wolne'};
  static const ofShort = {'en': 'of', 'pl': 'z'};

  // ----- Notification preferences (Phase 2E) -----
  static const notificationsMenu = {
    'en': 'Notifications…',
    'pl': 'Powiadomienia…',
  };
  static const notificationsTitle = {
    'en': 'Notifications',
    'pl': 'Powiadomienia',
  };
  static const sectionQuietHours = {
    'en': 'Quiet hours',
    'pl': 'Ciche godziny',
  };
  static const quietHoursToggle = {
    'en': 'Enable quiet hours',
    'pl': 'Włącz ciche godziny',
  };
  static const quietStartLabel = {'en': 'Start', 'pl': 'Początek'};
  static const quietEndLabel = {'en': 'End', 'pl': 'Koniec'};
  static const quietOverrideLabel = {
    'en': 'Always deliver at or above',
    'pl': 'Zawsze dostarcz przy lub powyżej',
  };
  static const sectionFloor = {
    'en': 'Severity floor',
    'pl': 'Próg ważności',
  };
  static const minSeverityLabel = {
    'en': 'Never push below',
    'pl': 'Nigdy nie wysyłaj poniżej',
  };
  static const sevOk = {'en': 'OK', 'pl': 'OK'};
  static const sevInfo = {'en': 'Info', 'pl': 'Info'};
  static const sevWarn = {'en': 'Warning', 'pl': 'Ostrzeżenie'};
  static const sevCritical = {'en': 'Critical', 'pl': 'Krytyczne'};
  static const quietHoursHint = {
    'en':
        'Inside the window, alerts below the override threshold are silenced. Times are in this device\'s local clock.',
    'pl':
        'Wewnątrz okna alerty poniżej progu są wyciszane. Godziny w czasie lokalnym tego urządzenia.',
  };
  static const minSeverityHint = {
    'en':
        'A global floor — alerts below this never push, regardless of quiet hours.',
    'pl':
        'Globalny próg — alerty poniżej nigdy nie wysyłają, niezależnie od cichych godzin.',
  };
  static const sectionGrouping = {
    'en': 'Smart grouping',
    'pl': 'Inteligentne grupowanie',
  };
  static const cooldownLabel = {
    'en': 'Repeat cooldown',
    'pl': 'Przerwa przed powtórzeniem',
  };
  static const cooldownHint = {
    'en':
        'A check at the same severity won\'t push twice within this window. Escalation (severity went up) always punches through. Set to 0 to push on every run.',
    'pl':
        'Check przy tej samej severity nie wyśle drugiego pusha w tym oknie. Eskalacja (wzrost severity) zawsze przebija. 0 = push przy każdym uruchomieniu.',
  };
  static const cooldownHours = {
    'en': '{n} hours',
    'pl': '{n} godzin',
  };
  static const cooldownOff = {'en': 'Off', 'pl': 'Wyłączone'};

  static const sectionPerCheck = {
    'en': 'Per-check muting',
    'pl': 'Wyciszanie per check',
  };
  static const perCheckHint = {
    'en':
        'Toggle off any check you don\'t want push notifications about. If a run\'s only actionable checks are all muted, the device gets no push for it.',
    'pl':
        'Wyłącz checki o których nie chcesz dostawać powiadomień. Jeśli wszystkie aktywne checki w danym uruchomieniu są wyciszone, urządzenie nie dostanie pusha.',
  };
  static const checksLoading = {
    'en': 'Loading checks…',
    'pl': 'Wczytywanie checków…',
  };
  static const prefsSavedSnack = {
    'en': 'Notification preferences saved',
    'pl': 'Zapisano ustawienia powiadomień',
  };

  // ----- Errors (humanizer) -----
  static const errCannotReachTitle = {
    'en': 'Cannot reach server',
    'pl': 'Nie można połączyć się z serwerem',
  };
  static const errCannotReachBody = {
    'en':
        'No connection to the server. Check your internet, or whether the watchlog daemon is up and the URL is correct.',
    'pl':
        'Brak połączenia z serwerem. Sprawdź internet albo czy daemon watchlog działa i URL jest poprawny.',
  };
  static const errTimeoutTitle = {
    'en': 'Request timed out',
    'pl': 'Przekroczono czas oczekiwania',
  };
  static const errTimeoutBody = {
    'en':
        'The server took too long to respond. Check that the daemon is running and reachable.',
    'pl':
        'Serwer odpowiada za wolno. Sprawdź czy daemon działa i jest dostępny.',
  };
  static const errCertTitle = {
    'en': 'Certificate problem',
    'pl': 'Problem z certyfikatem',
  };
  static const errCertBody = {
    'en':
        "The server's TLS certificate is invalid or expired. The app refuses to send your token over an insecure connection.",
    'pl':
        'Certyfikat TLS serwera jest niepoprawny lub wygasł. Aplikacja nie wyśle tokenu po niezabezpieczonym połączeniu.',
  };
  static const errCancelledTitle = {
    'en': 'Request cancelled',
    'pl': 'Żądanie anulowane',
  };
  static const errCancelledBody = {
    'en': 'The request was cancelled.',
    'pl': 'Żądanie zostało anulowane.',
  };
  static const errNetworkTitle = {
    'en': 'Network error',
    'pl': 'Błąd sieci',
  };
  static const errNetworkBody = {
    'en': 'Request failed before reaching the server.',
    'pl': 'Żądanie nie dotarło do serwera.',
  };
  static const errBadRequestTitle = {
    'en': 'Bad request',
    'pl': 'Niepoprawne żądanie',
  };
  static const errBadRequestBody = {
    'en':
        'The server rejected the request shape. This usually means the app and server are on incompatible versions.',
    'pl':
        'Serwer odrzucił żądanie. Zwykle oznacza to niezgodne wersje aplikacji i serwera.',
  };
  static const errTokenRejectedTitle = {
    'en': 'Token rejected',
    'pl': 'Token odrzucony',
  };
  static const errTokenRejectedBody = {
    'en':
        'Your device token is invalid or has been revoked. Re-pair this server from Settings.',
    'pl':
        'Twój token urządzenia jest niepoprawny lub został odwołany. Sparuj serwer ponownie w Ustawieniach.',
  };
  static const errPermissionTitle = {
    'en': 'Permission denied',
    'pl': 'Brak uprawnień',
  };
  static const errPermissionBody = {
    'en':
        "Your token doesn't include the scope this action needs. Re-pair with broader scopes on the server (watchlog api qr).",
    'pl':
        'Twój token nie ma zakresu wymaganego dla tej akcji. Sparuj ponownie z szerszymi uprawnieniami (watchlog api qr).',
  };
  static const errNotFoundTitle = {
    'en': 'Not found',
    'pl': 'Nie znaleziono',
  };
  static const errNotFoundBody = {
    'en':
        "The server doesn't expose this endpoint. The watchlog backend may need to be upgraded.",
    'pl':
        'Serwer nie udostępnia tego endpointu. Backend watchlog może wymagać aktualizacji.',
  };
  static const errRateLimitTitle = {
    'en': 'Too many requests',
    'pl': 'Zbyt wiele żądań',
  };
  static const errRateLimitBody = {
    'en': 'Rate limit hit. Wait a minute, then try again.',
    'pl': 'Przekroczono limit. Poczekaj minutę i spróbuj ponownie.',
  };
  static const errNoDataTitle = {
    'en': 'No data yet',
    'pl': 'Jeszcze brak danych',
  };
  static const errNoDataBody = {
    'en':
        "The server hasn't completed a watchlog run yet, so there is no heartbeat to show. Tap \"Run now\" to trigger one.",
    'pl':
        'Serwer jeszcze nie uruchomił watchlog, więc nie ma czego pokazać. Naciśnij "Uruchom teraz".',
  };
  static const errServerTitle = {
    'en': 'Server error',
    'pl': 'Błąd serwera',
  };
  static const errServerBody = {
    'en':
        'The watchlog daemon returned an error. Check the server logs (journalctl -u watchlog-api).',
    'pl':
        'Daemon watchlog zwrócił błąd. Sprawdź logi serwera (journalctl -u watchlog-api).',
  };
  static const errUnknownTitle = {
    'en': 'Unexpected error',
    'pl': 'Nieoczekiwany błąd',
  };
  static const errUnknownBody = {
    'en':
        'Something went wrong. Tap "Show details" to see the raw error.',
    'pl':
        'Coś poszło nie tak. Naciśnij "Pokaż szczegóły" by zobaczyć surowy błąd.',
  };
  static const errRequestFailedHttp = {
    'en': 'Request failed (HTTP {status})',
    'pl': 'Żądanie nieudane (HTTP {status})',
  };
  static const errRequestFailedBody = {
    'en':
        'The server returned an unexpected status. Tap "Show details" for the raw response.',
    'pl':
        'Serwer zwrócił nieoczekiwany status. Naciśnij "Pokaż szczegóły".',
  };
  static const rawErrorLabel = {
    'en': 'Raw error',
    'pl': 'Surowy błąd',
  };
}

/// Pick the best translation for the user's effective locale.
/// Falls back to English; if a key is also missing in English, returns
/// the first available value or empty string.
String tr(BuildContext context, Map<String, String> messages, {
  Map<String, String>? subs,
}) {
  if (messages.isEmpty) return '';
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  String value = messages[code] ?? messages['en'] ?? messages.values.first;
  if (subs != null) {
    subs.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
  }
  return value;
}
