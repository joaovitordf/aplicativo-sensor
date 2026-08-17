import 'package:sensortech/features/auth/auth_controller.dart';

/// Extension helpers on [AuthController] for permissions and navigation rules.
extension AuthHelpers on AuthController {
  /// Check if the user has access to a specific tab
  bool hasTab(String tabName) {
    if (allowedTabs.isEmpty) return true; // Default allow if none specified
    return allowedTabs.contains(tabName.toLowerCase());
  }

  /// Whether the user can access the Central de Alertas / Galeria
  bool get hasCentralAlertas =>
      hasTab('alertas') || hasTab('galeria') || isCliente || isAdmin;

  /// Whether the user can access Detecção de Valas
  bool get hasSaneamento =>
      hasTab('saneamento') || hasTab('valas') || hasTab('alertas') || hasTab('galeria') || isCliente || isAdmin;

  /// Whether the user can access Câmera VMS
  bool get hasVms => hasTab('vms');

  /// Whether the user can access Equipamentos IoT
  bool get hasEquipamentosIot =>
      hasTab('equipamentos') ||
      hasTab('iot') ||
      hasTab('equipamentosiot') ||
      isAdmin ||
      isCliente;

  /// Whether the user is an admin or client
  bool get isCliente => role.toLowerCase() == 'cliente';
  bool get isAdmin => role.toLowerCase().contains('admin');
  bool get isSuperAdmin =>
      role.toLowerCase() == 'superadmin' ||
      role.toLowerCase() == 'admin' ||
      role.toLowerCase() == 'super';
}
