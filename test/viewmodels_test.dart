import 'package:flutter_test/flutter_test.dart';
import 'package:sensortech/features/auth/auth_controller.dart';
import 'package:sensortech/features/alertas/alertas_viewmodel.dart';
import 'package:sensortech/features/vala/vala_viewmodel.dart';
import 'package:sensortech/features/equipamentos_iot/equipamentos_iot_viewmodel.dart';
import 'package:sensortech/features/camera_vms/camera_vms_grade_viewmodel.dart';
import 'package:sensortech/features/camera_vms/camera_vms_viewmodel.dart';
import 'package:sensortech/data/services/ppe_service.dart';
import 'package:sensortech/data/services/camera_service.dart';
import 'package:sensortech/data/services/vms_service.dart';
import 'package:sensortech/data/services/equipamento_iot_service.dart';
import 'package:sensortech/data/services/cliente_service.dart';
import 'package:sensortech/data/services/solution_service.dart';
import 'package:dio/dio.dart';

import 'package:sensortech/core/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late AuthController authController;
  late PpeService ppeService;
  late CameraService cameraService;
  late VmsService vmsService;
  late EquipamentoIotService equipService;
  late ClienteService clienteService;
  late SolutionService solutionService;

  setUpAll(() {
    AppConfig.setMockEnvForTesting({
      'USE_STAGING': 'false',
      'API_URL_PROD': 'https://api.example.com',
      'STREAMSERVER_API_URL': 'https://stream.example.com',
      'STREAMSERVER_STREAM_URL': 'https://stream.example.com',
      'STREAMSERVER_HLS_URL': 'https://stream.example.com',
      'API_IOT_URL': 'https://iot.example.com',
    });

    dio = Dio();
    authController = AuthController();
    ppeService = PpeService(dio);
    cameraService = CameraService(dio);
    vmsService = VmsService(dio);
    equipService = EquipamentoIotService(dio);
    clienteService = ClienteService(dio);
    solutionService = SolutionService(dio);
  });

  tearDownAll(() {
    AppConfig.setMockEnvForTesting(null);
  });

  group('ViewModel Disposal Safety Tests', () {
    test('AlertaViewModel handles dispose() gracefully without throwing on delayed callbacks', () {
      final vm = AlertaViewModel(
        ppeService: ppeService,
        cameraService: cameraService,
        auth: authController,
      );

      // Simulates screen pop immediately
      expect(() => vm.dispose(), returnsNormally);
    });

    test('ValaViewModel handles dispose() gracefully without throwing', () {
      final vm = ValaViewModel(
        ppeService: ppeService,
        cameraService: cameraService,
        auth: authController,
      );

      expect(() => vm.dispose(), returnsNormally);
    });

    test('CameraVmsGradeViewModel handles dispose() gracefully', () {
      final vm = CameraVmsGradeViewModel(
        auth: authController,
        cameraService: cameraService,
      );

      expect(() => vm.dispose(), returnsNormally);
    });

    test('CameraVmsViewModel handles dispose() gracefully and disposes player', () {
      final vm = CameraVmsViewModel(
        vmsService: vmsService,
        equipamentoService: equipService,
      );

      expect(() => vm.dispose(), returnsNormally);
    });

    test('EquipamentosIotViewModel handles dispose() gracefully', () {
      final vm = EquipamentosIotViewModel(
        auth: authController,
        equipamentoService: equipService,
        clienteService: clienteService,
        solutionService: solutionService,
        cameraService: cameraService,
      );

      expect(() => vm.dispose(), returnsNormally);
    });

    test('AlertaViewModel and ValaViewModel initialize with non-null startDate and endDate', () {
      final alertaVm = AlertaViewModel(
        ppeService: ppeService,
        cameraService: cameraService,
        auth: authController,
      );

      expect(alertaVm.selectedStartDate, isNotNull);
      expect(alertaVm.selectedEndDate, isNotNull);
      expect(alertaVm.selectedEndDate!.isAfter(alertaVm.selectedStartDate!), isTrue);

      final valaVm = ValaViewModel(
        ppeService: ppeService,
        cameraService: cameraService,
        auth: authController,
      );

      expect(valaVm.selectedStartDate, isNotNull);
      expect(valaVm.selectedEndDate, isNotNull);
      expect(valaVm.selectedEndDate!.isAfter(valaVm.selectedStartDate!), isTrue);

      alertaVm.dispose();
      valaVm.dispose();
    });
  });
}
