/// Applies a non-default HTTP User-Agent so Scryfall's image CDN
/// (`cards.scryfall.io`) does not reject image requests with HTTP 400.
///
/// Flutter's `Image.network` loads images through dart:io's `HttpClient`,
/// which sends the default `Dart/<version> (dart:io)` User-Agent. Scryfall
/// blocks that exact agent with a 400, breaking every commander image in the
/// app. Setting a descriptive User-Agent fixes all network images at once.
///
/// No-op on web, where the browser supplies its own User-Agent.
library;

// ignore: conditional_uri_does_not_exist
export 'scryfall_user_agent_stub.dart'
    if (dart.library.io) 'scryfall_user_agent_io.dart';
