@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/app/utils/scryfall_user_agent.dart';

void main() {
  test('installs a non-default User-Agent so Scryfall stops returning 400', () {
    applyScryfallUserAgent();

    // HttpClient() honours the global HttpOverrides, so the client Flutter's
    // NetworkImage builds the same way inherits this User-Agent. The default
    // Dart agent ("Dart/<version> (dart:io)") is what Scryfall rejects.
    final client = HttpClient();
    addTearDown(client.close);

    expect(client.userAgent, isNotNull);
    expect(client.userAgent, isNot(startsWith('Dart/')));
    expect(client.userAgent, contains('MagicYeti'));
  });
}
