import 'dart:io';

/// Installs a global [HttpOverrides] giving every dart:io [HttpClient] —
/// including the shared client Flutter's `NetworkImage` uses — a descriptive
/// User-Agent, so Scryfall's image CDN stops returning HTTP 400.
///
/// Call once during startup, before the first image loads.
void applyScryfallUserAgent() {
  HttpOverrides.global = _MagicYetiHttpOverrides();
}

class _MagicYetiHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = 'MagicYeti/1.0 (+https://github.com/Jshewmaker/magic_yeti_v2)';
  }
}
