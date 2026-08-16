import 'package:sensortech/data/models/camera_model.dart';

/// A single recording segment with a start timestamp.
class RecordingSegment {
  final DateTime start;
  final String? originalStartString;

  RecordingSegment({
    required this.start,
    this.originalStartString,
  });

  factory RecordingSegment.fromJson(Map<String, dynamic> json) {
    final startVal = json['start'];
    if (startVal == null) {
      return RecordingSegment(start: DateTime.now());
    }
    final startStr = startVal.toString();

    // Manual parsing to extract wall-clock time regardless of timezone/offset.
    // Handles "14:46-03:00" → display 14:46 correctly.
    DateTime start;
    try {
      final tIndex = startStr.indexOf('T');
      if (tIndex != -1) {
        final tzPattern = RegExp(r'[+-]\d{2}(?::?\d{2})?|Z$');
        final match = tzPattern.firstMatch(startStr.substring(tIndex + 1));

        if (match != null) {
          final wallClockPart = startStr.substring(0, tIndex + 1 + match.start);
          start = DateTime.parse(wallClockPart);
        } else {
          start = DateTime.parse(startStr);
        }
      } else {
        start = DateTime.parse(startStr);
      }
    } catch (_) {
      start = DateTime.parse(startStr);
    }

    return RecordingSegment(
      start: start,
      originalStartString: startStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {'start': start.toIso8601String()};
  }

  /// Date portion for grouping by day.
  DateTime get date => DateTime(start.year, start.month, start.day);

  /// Time portion as HH:mm:ss string.
  String get timeString =>
      '${start.hour.toString().padLeft(2, '0')}:'
      '${start.minute.toString().padLeft(2, '0')}:'
      '${start.second.toString().padLeft(2, '0')}';
}

/// Represents a camera's recording entry with all its segments.
class Recording {
  /// VMS path in format "idCliente/idCamera" (e.g. "8/45").
  final String name;

  /// Segments loaded lazily per camera.
  List<RecordingSegment> segments;

  /// Optional reference to the backend Camera object.
  Camera? cameraInfo;

  Recording({
    required this.name,
    required this.segments,
    this.cameraInfo,
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      name: json['name'] as String,
      segments: (json['segments'] as List?)
              ?.map((item) =>
                  RecordingSegment.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// All unique dates that have recordings, sorted ascending.
  List<DateTime> get recordingDates {
    final dates = <DateTime>{};
    for (final segment in segments) {
      dates.add(segment.date);
    }
    return dates.toList()..sort();
  }

  /// Get segments for a specific calendar date.
  List<RecordingSegment> getSegmentsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return segments.where((seg) => seg.date == targetDate).toList();
  }
}
