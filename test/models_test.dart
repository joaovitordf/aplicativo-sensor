import 'package:flutter_test/flutter_test.dart';
import 'package:sensortech/data/models/auth_model.dart';
import 'package:sensortech/data/models/ppe_event_model.dart';
import 'package:sensortech/data/models/camera_model.dart';
import 'package:sensortech/data/models/recording_model.dart';
import 'package:sensortech/data/models/equipamento_iot_model.dart';
import 'package:sensortech/data/models/solution_model.dart';
import 'package:sensortech/data/models/cliente_detailed_model.dart';

void main() {
  group('AuthModel Tests', () {
    test('Parse LoginResponse correctly from real API JSON sample', () {
      final sampleJson = {
        "allowed_tabs": ["galeria", "alertas", "dashboard", "vms"],
        "client_name": "Cliente Teste",
        "token": "mock_token_abc123_xyz",
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

      expect(response.token, "mock_token_abc123_xyz");
      expect(response.clientName, "Cliente Teste");
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

  group('CameraModel Tests', () {
    test('Parse Camera correctly from real API JSON sample', () {
      final sampleJson = {
        "NomeCamera": "BBLENG - CAM-1A2 - ENG7H46 - EQUIPE6 - CAM02 - 1",
        "agent_enabled": 1,
        "camera_id": 24,
        "client_id": 8,
        "conf_min": 0.6,
        "conformity_interval": 30,
        "cooldown_min": 5,
        "created": "2026-07-09 23:22:44",
        "display_classes": "{\"helmet\": 0, \"no_helmet\": 1}",
        "group_id": null,
        "id": "45",
        "idCameraP2p": null,
        "idCliente": "49",
        "last_seen": null,
        "linkHLS": "http://streamserver.example.com:8888/8/45/index.m3u8",
        "linkcamera": "rtsp://admin:123456@192.168.1.100:554/stream",
        "Tipoconexao": 1,
        "gravar": 1
      };

      final camera = Camera.fromJson(sampleJson);

      expect(camera.id, 45);
      expect(camera.cameraId, 24);
      expect(camera.displayId, 24);
      expect(camera.nomeCamera, "BBLENG - CAM-1A2 - ENG7H46 - EQUIPE6 - CAM02 - 1");
      expect(camera.idCliente, 49);
      expect(camera.linkHLS, "http://streamserver.example.com:8888/8/45/index.m3u8");
      expect(camera.linkcamera, "rtsp://admin:123456@192.168.1.100:554/stream");
      expect(camera.tipoConexao, 1);
      expect(camera.gravar, 1);
      expect(camera.hasHLSStream, true);
      expect(camera.hasRTSPStream, true);
      expect(camera.vmsPathName, "49/45");
      expect(camera.confMin, 0.6);
    });
  });

  group('RecordingModel Tests', () {
    test('Parse RecordingSegment with timezone offset without shifting wall-clock time', () {
      final sample = {
        'start': '2026-08-15T14:46:30-03:00'
      };

      final segment = RecordingSegment.fromJson(sample);

      expect(segment.timeString, '14:46:30');
      expect(segment.date, DateTime(2026, 8, 15));
    });

    test('Recording group segments by date', () {
      final recording = Recording(
        name: '8/45',
        segments: [
          RecordingSegment(start: DateTime(2026, 8, 14, 10, 0, 0)),
          RecordingSegment(start: DateTime(2026, 8, 14, 11, 0, 0)),
          RecordingSegment(start: DateTime(2026, 8, 15, 14, 30, 0)),
        ],
      );

      expect(recording.recordingDates.length, 2);
      expect(recording.getSegmentsForDate(DateTime(2026, 8, 14)).length, 2);
      expect(recording.getSegmentsForDate(DateTime(2026, 8, 15)).length, 1);
    });

    test('Recording groups continuous 5-second chunks into unified sessions', () {
      final recording = Recording(
        name: '49/118',
        segments: [
          // Session 1: 02:30:00 to 02:30:15 (4 chunks of 5s)
          RecordingSegment(start: DateTime(2026, 8, 16, 2, 30, 0)),
          RecordingSegment(start: DateTime(2026, 8, 16, 2, 30, 5)),
          RecordingSegment(start: DateTime(2026, 8, 16, 2, 30, 10)),
          RecordingSegment(start: DateTime(2026, 8, 16, 2, 30, 15)),
          // Gap of 2 hours
          // Session 2: 04:30:00 to 04:30:05 (2 chunks)
          RecordingSegment(start: DateTime(2026, 8, 16, 4, 30, 0)),
          RecordingSegment(start: DateTime(2026, 8, 16, 4, 30, 5)),
        ],
      );

      final grouped = recording.getGroupedSegmentsForDate(DateTime(2026, 8, 16));

      expect(grouped.length, 2);

      // Session 1 checks
      expect(grouped[0].timeString, '02:30:00');
      expect(grouped[0].durationSeconds, 25); // (15 - 0) + 10s = 25s
      expect(grouped[0].formattedDuration, '25s');

      // Session 2 checks
      expect(grouped[1].timeString, '04:30:00');
      expect(grouped[1].durationSeconds, 15);
      expect(grouped[1].formattedDuration, '15s');
    });

    test('RecordingSegment duration formatting helper returns human-readable text', () {
      final segShort = RecordingSegment(start: DateTime.now(), durationSeconds: 45);
      expect(segShort.formattedDuration, '45s');

      final segMins = RecordingSegment(start: DateTime.now(), durationSeconds: 650);
      expect(segMins.formattedDuration, '10min 50s');

      final segHours = RecordingSegment(start: DateTime.now(), durationSeconds: 3660);
      expect(segHours.formattedDuration, '1h 1min');

      final segExactHours = RecordingSegment(start: DateTime.now(), durationSeconds: 7200);
      expect(segExactHours.formattedDuration, '2h');
    });
  });

  group('EquipamentoIotModel Tests', () {
    test('Parse EquipamentoIot correctly from JSON sample', () {
      final sample = {
        "id": 12,
        "nomeEquipamento": "Raspberry PI - Posto 01",
        "enderecoInstalacao": "Canteiro Central",
        "modeloEquipamento": "Raspberry Pi 4",
        "localizacao": "Setor A",
        "ipEquipamento": "192.168.1.50",
        "tipoConexao": 1,
        "idCliente": 8,
        "dataHora": "2026-08-01 10:00:00",
        "enabled": 1,
        "idSolucoes": [1, 2],
      };

      final eq = EquipamentoIot.fromJson(sample);

      expect(eq.id, 12);
      expect(eq.nomeEquipamento, "Raspberry PI - Posto 01");
      expect(eq.enderecoInstalacao, "Canteiro Central");
      expect(eq.modeloEquipamento, "Raspberry Pi 4");
      expect(eq.ipEquipamento, "192.168.1.50");
      expect(eq.idCliente, 8);
      expect(eq.isAtivo, true);
      expect(eq.idSolucoes, [1, 2]);
    });
  });

  group('SolutionModel Tests', () {
    test('Parse Solution correctly from JSON sample', () {
      final sample = {
        "id": 1,
        "label": "EPI - Segurança do Trabalho",
        "usaIA": 1,
        "idModeloIA": 5,
        "modelo": {
          "id": 5,
          "nomeObjeto": "EPI Detecção",
          "modeloVersao": "1.0",
          "status": "ativo",
          "arquivoNome": "epi.pt",
          "classes": [
            {"id": 1, "className": "helmet", "status": "ativo", "classIndex": 0},
            {"id": 2, "className": "vest", "status": "ativo", "classIndex": 1}
          ]
        }
      };

      final sol = Solution.fromJson(sample);

      expect(sol.id, 1);
      expect(sol.label, "EPI - Segurança do Trabalho");
      expect(sol.usesAI, true);
      expect(sol.modelo?.classes.length, 2);
      expect(sol.modelo?.classes[0].className, "helmet");
    });
  });

  group('ClienteDetailedModel Tests', () {
    test('Parse ClienteDetailed correctly from JSON sample', () {
      final sample = {
        "id": 8,
        "cnpj": "12.345.678/0001-90",
        "razaoSocial": "Construtora Alfa S.A.",
        "nomeFantasia": "Alfa Construções",
        "telefone": "(11) 98888-7777",
        "email": "contato@alfa.com.br",
        "solucoes": [1, 3]
      };

      final cli = ClienteDetailed.fromJson(sample);

      expect(cli.id, 8);
      expect(cli.cnpj, "12.345.678/0001-90");
      expect(cli.razaoSocial, "Construtora Alfa S.A.");
      expect(cli.displayName, "Alfa Construções");
      expect(cli.solucoes, [1, 3]);
    });
  });
}


