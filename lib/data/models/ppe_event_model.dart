import 'dart:convert';
import 'package:intl/intl.dart';

/// Mapping of EPI keys to user-friendly Portuguese labels.
const Map<String, String> kEpiTranslations = {
  // Infrações / Ausências de EPI
  'no_helmet': 'Sem Capacete',
  'no-helmet': 'Sem Capacete',
  'no_gloves': 'Sem Luvas',
  'no-gloves': 'Sem Luvas',
  'no_vest': 'Sem Colete',
  'no-vest': 'Sem Colete',
  'no_mask': 'Sem Máscara',
  'no-mask': 'Sem Máscara',
  'no_ear': 'Sem Protetor Auricular',
  'no-ear': 'Sem Protetor Auricular',
  'no_earplug': 'Sem Protetor Auricular',
  'no_earmuffs': 'Sem Protetor Auricular',
  'no_fita_adesiva': 'Sem Fita Adesiva',
  'no-fita-adesiva': 'Sem Fita Adesiva',
  'no_fita': 'Sem Fita Adesiva',
  'no_tape': 'Sem Fita Adesiva',
  'no_boot': 'Sem Botas',
  'no_boots': 'Sem Botas',
  'no_shoes': 'Sem Botas',
  'no_glasses': 'Sem Óculos',
  'no_goggles': 'Sem Óculos',
  'no_harness': 'Sem Cinto de Segurança',
  'sem_capacete': 'Sem Capacete',
  'sem_luvas': 'Sem Luvas',
  'sem_colete': 'Sem Colete',
  'sem_mascara': 'Sem Máscara',
  'sem_protetor_auricular': 'Sem Protetor Auricular',
  'sem_fita_adesiva': 'Sem Fita Adesiva',
  'sem_bota': 'Sem Botas',
  'sem_botas': 'Sem Botas',
  'sem_oculos': 'Sem Óculos',
  'sem_cinto': 'Sem Cinto de Segurança',

  // Detecções e Eventos
  'presenca_vala': 'Presença de Vala',
  'presenca-vala': 'Presença de Vala',
  'vala': 'Presença de Vala',
  'trench': 'Presença de Vala',
  'presenca_escora': 'Presença de Escora',
  'presenca-escora': 'Presença de Escora',
  'escora': 'Presença de Escora',
  'shoring': 'Presença de Escora',
  'registro_conformidade': 'Registro de Conformidade',
  'conformidade': 'Registro de Conformidade',
  'conforme': 'Conforme',

  // Itens de EPI
  'capacete': 'Capacete',
  'helmet': 'Capacete',
  'luvas': 'Luvas',
  'luva': 'Luvas',
  'gloves': 'Luvas',
  'glove': 'Luvas',
  'colete': 'Colete',
  'vest': 'Colete',
  'jacket': 'Colete',
  'mascara': 'Máscara',
  'mask': 'Máscara',
  'protetor_auricular': 'Protetor Auricular',
  'ear': 'Protetor Auricular',
  'earplug': 'Protetor Auricular',
  'earmuffs': 'Protetor Auricular',
  'fita_adesiva': 'Fita Adesiva',
  'fita': 'Fita Adesiva',
  'tape': 'Fita Adesiva',
  'bota': 'Botas',
  'botas': 'Botas',
  'boot': 'Botas',
  'boots': 'Botas',
  'oculos': 'Óculos',
  'glasses': 'Óculos',
  'goggles': 'Óculos',
  'cinto': 'Cinto de Segurança',
  'harness': 'Cinto de Segurança',
  'cinto_seguranca': 'Cinto de Segurança',

  // Estados e tipos
  'ausencia': 'Ausência de EPI',
  'nao_conforme': 'Não Conforme',
  'alerta': 'Alerta',
};

String translateEpi(String key) {
  final cleanKey = key.trim().toLowerCase().replaceAll('"', '').replaceAll("'", '');
  if (kEpiTranslations.containsKey(cleanKey)) {
    return kEpiTranslations[cleanKey]!;
  }
  
  // Fallback inteligente para termos no_ / no- desconhecidos
  if (cleanKey.startsWith('no_') || cleanKey.startsWith('no-')) {
    final sub = cleanKey.substring(3);
    if (kEpiTranslations.containsKey(sub)) {
      return 'Sem ${kEpiTranslations[sub]}';
    }
    return 'Sem ${sub.replaceAll('_', ' ').replaceAll('-', ' ')}';
  }
  
  // Fallback para formatação limpa sem underscores
  final formatted = cleanKey.replaceAll('_', ' ').replaceAll('-', ' ');
  return formatted.isNotEmpty ? '${formatted[0].toUpperCase()}${formatted.substring(1)}' : key;
}

/// Model representing a PPE event from GET /api/ppe/events.
class PpeEvent {
  final int id;
  final int? cameraId;
  final int? clientId;
  final double? confidence;
  final String? eventType;
  final int? frameH;
  final int? frameW;
  final String? framePath;
  final String? frameLimpoPath;
  final List<String> missingPpe;
  final String? modeloVersao;
  final dynamic personTrackId;
  final dynamic sessionId;
  final String? state;
  final String? ts;

  PpeEvent({
    required this.id,
    this.cameraId,
    this.clientId,
    this.confidence,
    this.eventType,
    this.frameH,
    this.frameW,
    this.framePath,
    this.frameLimpoPath,
    required this.missingPpe,
    this.modeloVersao,
    this.personTrackId,
    this.sessionId,
    this.state,
    this.ts,
  });

  /// Parse timestamp string into DateTime
  DateTime? get timestamp {
    if (ts == null || ts!.isEmpty) return null;
    try {
      return DateTime.parse(ts!);
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd HH:mm:ss').parse(ts!);
      } catch (_) {
        return null;
      }
    }
  }

  /// Formatted date string for display (e.g. 13/08/2026 às 10:32)
  String get displayDate {
    final t = timestamp;
    if (t != null) {
      return DateFormat("dd/MM/yyyy 'às' HH:mm:ss").format(t);
    }
    return ts ?? 'Evento #$id';
  }

  /// Whether the event state represents a non-compliance (infração de EPI)
  bool get isNonCompliant =>
      state?.toUpperCase().contains('NAO_CONFORME') ?? true;

  /// Translated label of missing EPIs (e.g. "Sem Capacete, Sem Luvas, Sem Colete")
  String get translatedMissingPpe {
    if (missingPpe.isEmpty) {
      if (isNonCompliant) return 'Não Conforme';
      return 'Conforme';
    }
    final uniqueTranslations = <String>{};
    for (final item in missingPpe) {
      final t = translateEpi(item);
      if (t.isNotEmpty) {
        uniqueTranslations.add(t);
      }
    }
    if (uniqueTranslations.isEmpty) {
      return isNonCompliant ? 'Não Conforme' : 'Conforme';
    }
    return uniqueTranslations.join(', ');
  }

  factory PpeEvent.fromJson(Map<String, dynamic> json) {
    List<String> parseMissingPpe(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.expand((e) => parseMissingPpe(e)).toList();
      }
      if (value is String && value.isNotEmpty) {
        final trimmed = value.trim();
        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          try {
            final decoded = jsonDecode(trimmed);
            if (decoded is List) {
              return decoded.expand((e) => parseMissingPpe(e)).toList();
            }
          } catch (_) {
            // Se jsonDecode falhar (ex: formato sem aspas "[no_helmet, no_gloves]"), separa por vírgula
            final inner = trimmed.substring(1, trimmed.length - 1);
            return inner
                .split(',')
                .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } else if (trimmed.contains(',')) {
          return trimmed
              .split(',')
              .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
              .where((s) => s.isNotEmpty)
              .toList();
        }
        final cleaned = trimmed.replaceAll('"', '').replaceAll("'", '');
        return cleaned.isNotEmpty ? [cleaned] : [];
      }
      return [];
    }

    return PpeEvent(
      id: json['id'] as int? ?? 0,
      cameraId: json['camera_id'] as int?,
      clientId: json['client_id'] as int?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      eventType: json['event_type'] as String?,
      frameH: json['frame_h'] as int?,
      frameW: json['frame_w'] as int?,
      framePath: json['frame_path'] as String?,
      frameLimpoPath: json['frame_limpo_path'] as String?,
      missingPpe: parseMissingPpe(json['missing_ppe']),
      modeloVersao: json['modelo_versao'] as String?,
      personTrackId: json['person_track_id'],
      sessionId: json['session_id'],
      state: json['state'] as String?,
      ts: json['ts'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'camera_id': cameraId,
      'client_id': clientId,
      'confidence': confidence,
      'event_type': eventType,
      'frame_h': frameH,
      'frame_w': frameW,
      'frame_path': framePath,
      'frame_limpo_path': frameLimpoPath,
      'missing_ppe': missingPpe,
      'modelo_versao': modeloVersao,
      'person_track_id': personTrackId,
      'session_id': sessionId,
      'state': state,
      'ts': ts,
    };
  }
}

/// Paginated response from GET /api/ppe/events.
class PpeEventsResponse {
  final List<PpeEvent> events;

  PpeEventsResponse({required this.events});

  factory PpeEventsResponse.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'] as List? ?? [];
    return PpeEventsResponse(
      events: rawEvents
          .map((e) => PpeEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
