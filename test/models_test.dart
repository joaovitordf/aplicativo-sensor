import 'package:flutter_test/flutter_test.dart';
import 'package:sensortech/data/models/auth_model.dart';
import 'package:sensortech/data/models/ppe_event_model.dart';

void main() {
  group('AuthModel Tests', () {
    test('Parse LoginResponse correctly from real API JSON sample', () {
      final sampleJson = {
        "allowed_tabs": ["galeria", "alertas", "dashboard", "vms"],
        "client_name": "BBL",
        "token": "NPZPhmv-sp66rcFxOOR_s3Oe8jocq1eaWhR7hgIPhNo",
        "user": {
          "active": 1,
          "allowed_tabs": "[\"galeria\", \"alertas\", \"dashboard\", \"vms\"]",
          "client_id": 12,
          "created": "2026-08-14 21:43:22",
          "email": "joao",
          "id": 11,
          "name": "Joao",
          "phone": null,
          "role": "cliente",
          "username": "joao",
          "visible_groups": "[]"
        }
      };

      final response = LoginResponse.fromJson(sampleJson);

      expect(response.token, "NPZPhmv-sp66rcFxOOR_s3Oe8jocq1eaWhR7hgIPhNo");
      expect(response.clientName, "BBL");
      expect(response.allowedTabs, ["galeria", "alertas", "dashboard", "vms"]);
      expect(response.user.id, 11);
      expect(response.user.clientId, 12);
      expect(response.user.name, "Joao");
      expect(response.user.role, "cliente");
      expect(response.user.allowedTabs, ["galeria", "alertas", "dashboard", "vms"]);
    });
  });

  group('PpeEventModel Tests', () {
    test('Parse PpeEvent correctly from real API JSON sample', () {
      final sampleJson = {
        "camera_id": 16,
        "client_id": 12,
        "confidence": 0.652,
        "event_type": "ausencia",
        "frame_h": 720,
        "frame_limpo_consumido": null,
        "frame_limpo_path": "/home/epi/workspace/data/alerts/12/epi_12_16_limpo.jpg",
        "frame_path": "/home/epi/workspace/data/alerts/12/epi_12_16.jpg",
        "frame_w": 1280,
        "id": 5950,
        "missing_ppe": "[\"no_gloves\"]",
        "modelo_versao": "EPI_modelo.pt",
        "person_track_id": null,
        "session_id": null,
        "state": "NAO_CONFORME",
        "ts": "2026-08-13 10:32:16"
      };

      final event = PpeEvent.fromJson(sampleJson);

      expect(event.id, 5950);
      expect(event.cameraId, 16);
      expect(event.clientId, 12);
      expect(event.confidence, 0.652);
      expect(event.eventType, "ausencia");
      expect(event.missingPpe, ["no_gloves"]);
      expect(event.state, "NAO_CONFORME");
      expect(event.isNonCompliant, true);
      expect(event.translatedMissingPpe, "Sem Luvas");
      expect(event.timestamp, isNotNull);
      expect(event.displayDate, contains("13/08/2026"));
    });

    test('Translate multiple EPIs including no_vest and presenca_vala correctly', () {
      final event1 = PpeEvent(
        id: 1,
        missingPpe: ['no_vest'],
        state: 'NAO_CONFORME',
      );
      expect(event1.translatedMissingPpe, 'Sem Colete');

      final event2 = PpeEvent(
        id: 2,
        missingPpe: ['presenca_vala'],
        state: 'NAO_CONFORME',
      );
      expect(event2.translatedMissingPpe, 'Presença de Vala');

      final event3 = PpeEvent(
        id: 3,
        missingPpe: ['no_gloves', 'no_vest'],
        state: 'NAO_CONFORME',
      );
      expect(event3.translatedMissingPpe, 'Sem Luvas, Sem Colete');

      final event4 = PpeEvent(
        id: 4,
        missingPpe: ['No_vest', 'no-helmet', 'no_earmuffs', 'no_boot'],
        state: 'NAO_CONFORME',
      );
      expect(event4.translatedMissingPpe, 'Sem Colete, Sem Capacete, Sem Protetor Auricular, Sem Botas');

      final event5 = PpeEvent(
        id: 5,
        missingPpe: ['no_custom_item'],
        state: 'NAO_CONFORME',
      );
      expect(event5.translatedMissingPpe, 'Sem custom item');

      // Teste com 3 EPIs ausentes (Capacete, Luva e Colete)
      final event6 = PpeEvent.fromJson({
        'id': 6,
        'missing_ppe': '["no_helmet", "no_gloves", "no_vest"]',
        'state': 'NAO_CONFORME',
      });
      expect(event6.translatedMissingPpe, 'Sem Capacete, Sem Luvas, Sem Colete');

      final event7 = PpeEvent.fromJson({
        'id': 7,
        'missing_ppe': 'no_helmet, no_gloves, no_vest',
        'state': 'NAO_CONFORME',
      });
      expect(event7.translatedMissingPpe, 'Sem Capacete, Sem Luvas, Sem Colete');
    });
  });
}
