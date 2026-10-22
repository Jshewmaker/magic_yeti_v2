// Generates the compact commander index asset from Scryfall bulk data.
//
// Usage (run from this package's root):
//   dart run tool/generate_commander_index.dart [path-to-bulk-json] [output]
//
// With no arguments, the current "Unique Artwork" bulk data file (~250MB) is
// downloaded from Scryfall to a temporary location, processed, and deleted.
// Pass a path to use an already-downloaded bulk file instead. The output
// defaults to assets/cards/commander_index.json.
//
// Only commander-eligible cards (type line containing "Legendary" or
// "Background") are kept, and only the fields the app reads are projected,
// which shrinks the ~250MB bulk file to a few MB.
import 'dart:convert';
import 'dart:io';

const _defaultOutput = 'assets/cards/commander_index.json';
const _bulkDataCatalogUrl = 'https://api.scryfall.com/bulk-data';

Future<void> main(List<String> args) async {
  if (args.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/generate_commander_index.dart '
      '[path-to-bulk-json] [output]',
    );
    exitCode = 64;
    return;
  }

  File? downloaded;
  final File input;
  if (args.isEmpty) {
    downloaded = await _downloadUniqueArtworkBulkData();
    input = downloaded;
  } else {
    input = File(args[0]);
    if (!input.existsSync()) {
      stderr.writeln('Input file not found: ${args[0]}');
      exitCode = 66;
      return;
    }
  }
  final output = File(args.length > 1 ? args[1] : _defaultOutput);

  try {
    stdout.writeln('Parsing ${input.path}...');
    final cards = jsonDecode(input.readAsStringSync()) as List<dynamic>;
    final entries = <Map<String, dynamic>>[];
    for (final card in cards.cast<Map<String, dynamic>>()) {
      final entry = projectCard(card);
      if (entry != null) entries.add(entry);
    }

    output
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode(entries));
    stdout.writeln(
      'Wrote ${entries.length} of ${cards.length} cards '
      '(${(output.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB) '
      'to ${output.path}',
    );
  } finally {
    downloaded?.parent.deleteSync(recursive: true);
  }
}

/// Downloads the current unique-artwork bulk data file to a temporary
/// location and returns it. The caller is responsible for deleting it.
Future<File> _downloadUniqueArtworkBulkData() async {
  final httpClient = HttpClient();
  try {
    stdout.writeln('Fetching bulk data catalog from $_bulkDataCatalogUrl...');
    final catalog =
        jsonDecode(await _get(httpClient, Uri.parse(_bulkDataCatalogUrl)))
            as Map<String, dynamic>;
    final uniqueArtwork = (catalog['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (bulk) => bulk['type'] == 'unique_artwork',
          orElse: () => throw Exception(
            'No unique_artwork entry in the Scryfall bulk data catalog',
          ),
        );
    final downloadUri = Uri.parse(uniqueArtwork['download_uri'] as String);
    final sizeMb = (uniqueArtwork['size'] as int) / (1024 * 1024);

    final temp = File(
      '${Directory.systemTemp.createTempSync('scryfall_bulk').path}/'
      'unique_artwork.json',
    );
    stdout.writeln(
      'Downloading $downloadUri (${sizeMb.toStringAsFixed(0)} MB)...',
    );
    final request = await httpClient.getUrl(downloadUri);
    _setHeaders(request);
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException(
        'Download failed: ${response.statusCode}',
        uri: downloadUri,
      );
    }
    await response.pipe(temp.openWrite());
    return temp;
  } finally {
    httpClient.close();
  }
}

Future<String> _get(HttpClient httpClient, Uri uri) async {
  final request = await httpClient.getUrl(uri);
  _setHeaders(request);
  final response = await request.close();
  if (response.statusCode != 200) {
    throw HttpException('Request failed: ${response.statusCode}', uri: uri);
  }
  return response.transform(utf8.decoder).join();
}

void _setHeaders(HttpClientRequest request) {
  request.headers
    ..set(HttpHeaders.userAgentHeader, 'Magic Yeti/1.0')
    ..set(HttpHeaders.acceptHeader, 'application/json');
}

/// Projects a full Scryfall card object to a compact index entry, or returns
/// `null` if the card is not commander-eligible or has no usable image.
Map<String, dynamic>? projectCard(Map<String, dynamic> card) {
  final typeLine = (card['type_line'] as String?) ?? '';
  final lowerTypeLine = typeLine.toLowerCase();
  if (!lowerTypeLine.contains('legendary') &&
      !lowerTypeLine.contains('background')) {
    return null;
  }

  // Hoist the first face's art for double-faced cards, mirroring the image
  // normalization ScryfallRepository applies to search results.
  final imageUris = card['image_uris'] as Map<String, dynamic>?;
  var artCrop = imageUris?['art_crop'] as String?;
  if (artCrop == null) {
    final faces = card['card_faces'] as List<dynamic>?;
    final faceImageUris = faces == null || faces.isEmpty
        ? null
        : (faces.first as Map<String, dynamic>)['image_uris']
              as Map<String, dynamic>?;
    artCrop = faceImageUris?['art_crop'] as String?;
  }
  if (artCrop == null && card['image_status'] == 'missing') return null;

  return <String, dynamic>{
    'name': card['name'],
    if (card['oracle_id'] != null) 'oracle_id': card['oracle_id'],
    'type_line': typeLine,
    if (card['scryfall_uri'] != null) 'scryfall_uri': card['scryfall_uri'],
    if (card['edhrec_rank'] != null) 'edhrec_rank': card['edhrec_rank'],
    if (card['artist'] != null) 'artist': card['artist'],
    if (card['colors'] != null) 'colors': card['colors'],
    if (card['color_identity'] != null)
      'color_identity': card['color_identity'],
    if (card['mana_cost'] != null) 'mana_cost': card['mana_cost'],
    if (card['oracle_text'] != null) 'oracle_text': card['oracle_text'],
    if (card['power'] != null) 'power': card['power'],
    if (card['toughness'] != null) 'toughness': card['toughness'],
    if (card['keywords'] != null) 'keywords': card['keywords'],
    'art_crop': ?artCrop,
  };
}
