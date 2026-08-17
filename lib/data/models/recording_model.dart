import 'package:sensortech/data/models/camera_model.dart';

/// A single recording segment or continuous recording block with start/end timestamps.
class RecordingSegment {
  final DateTime start;
  final String? originalStartString;
  final DateTime? end;
  final int durationSeconds;

  RecordingSegment({
    required this.start,
    this.originalStartString,
    this.end,
    this.durationSeconds = 3600,
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
    return {
      'start': start.toIso8601String(),
      if (originalStartString != null)
        'originalStartString': originalStartString,
    };
  }

  /// Date portion for grouping by day.
  DateTime get date => DateTime(start.year, start.month, start.day);

  /// Time portion as HH:mm:ss string.
  String get timeString =>
      '${start.hour.toString().padLeft(2, '0')}:'
      '${start.minute.toString().padLeft(2, '0')}:'
      '${start.second.toString().padLeft(2, '0')}';

  /// End time portion as HH:mm:ss string (if available).
  String? get endTimeString {
    if (end == null) return null;
    return '${end!.hour.toString().padLeft(2, '0')}:'
        '${end!.minute.toString().padLeft(2, '0')}:'
        '${end!.second.toString().padLeft(2, '0')}';
  }

  /// Formatted duration label (e.g., "1h 15min", "10min 30s", "45s").
  String get formattedDuration {
    final d = durationSeconds;
    if (d >= 3600) {
      final hours = d ~/ 3600;
      final mins = (d % 3600) ~/ 60;
      return mins > 0 ? '${hours}h ${mins}min' : '${hours}h';
    } else if (d >= 60) {
      final mins = d ~/ 60;
      final secs = d % 60;
      return secs > 0 ? '${mins}min ${secs}s' : '${mins}min';
    } else {
      return '${d}s';
    }
  }
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

  /// Get raw segments for a specific calendar date.
  List<RecordingSegment> getSegmentsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return segments.where((seg) => seg.date == targetDate).toList();
  }

  /// Get continuous recording sessions/blocks for a specific calendar date.
  /// Groups raw chunk segments (<= 60s gap) into continuous sessions.
  List<RecordingSegment> getGroupedSegmentsForDate(DateTime date,
      {int gapThresholdSeconds = 60}) {
    final rawList = getSegmentsForDate(date);
    if (rawList.isEmpty) return [];

    final sorted = List<RecordingSegment>.from(rawList)
      ..sort((a, b) => a.start.compareTo(b.start));

    final List<RecordingSegment> grouped = [];
    RecordingSegment currentGroupStart = sorted.first;

    for (int i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      final isLast = i == sorted.length - 1;

      if (isLast) {
        final durationSec =
            current.start.difference(currentGroupStart.start).inSeconds + 10;
        grouped.add(RecordingSegment(
          start: currentGroupStart.start,
          originalStartString: currentGroupStart.originalStartString,
          end: current.start.add(const Duration(seconds: 10)),
          durationSeconds: durationSec >= 10 ? durationSec : 3600,
        ));
      } else {
        final next = sorted[i + 1];
        final gap = next.start.difference(current.start).inSeconds;

        if (gap > gapThresholdSeconds) {
          final durationSec =
              current.start.difference(currentGroupStart.start).inSeconds + 10;
          grouped.add(RecordingSegment(
            start: currentGroupStart.start,
            originalStartString: currentGroupStart.originalStartString,
            end: current.start.add(const Duration(seconds: 10)),
            durationSeconds: durationSec >= 10 ? durationSec : 3600,
          ));
          currentGroupStart = next;
        }
      }
    }

    return grouped;
  }
}
