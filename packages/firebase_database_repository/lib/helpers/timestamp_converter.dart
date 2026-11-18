import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// {@template timestamp_converter}
/// Converts between [DateTime] and [Timestamp] for JSON serialization.
/// {@endtemplate}
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  /// {@macro timestamp_converter}
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) {
    return timestamp.toDate();
  }

  @override
  Timestamp toJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}
