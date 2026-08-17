/// Camera model matching the backend `/api/v1/cameras` response.
class Camera {
  final int id;
  final int? cameraId;
  final String nomeCamera;
  final String linkcamera;
  final String linkHLS;
  final int tipoConexao;
  final int idCliente;
  final int gravar;
  final int enabled;
  final String? localizacao;
  final String? endCam;
  final String? modeloCam;
  final String? localEmp;
  final String? dataHora;
  final int? idSolucao;
  final String? resolucao;
  final String? numSerial;
  final String? codvalidacao;
  final int? diasgravacao;
  final String? timezone;
  final int? configRefreshSec;
  final int? statusIA;
  final String? provedor;
  final int? protocolo;
  final int? rtspExterno;
  final String? usuario;
  final String? senha;
  final String? host;
  final String? porta;
  final String? caminho;
  final String? servidor;
  final int? idCameraP2p;
  final int? entradaSaida;
  final int? agentEnabled;
  final double? confMin;
  final int? conformityInterval;
  final int? cooldownMin;
  final String? displayClasses;
  final String? requiredPpe;
  final String? roiJson;
  final String? vmsJson;
  final String? lastSeen;

  Camera({
    required this.id,
    this.cameraId,
    required this.nomeCamera,
    required this.linkcamera,
    required this.linkHLS,
    required this.tipoConexao,
    required this.idCliente,
    required this.gravar,
    required this.enabled,
    this.localizacao,
    this.endCam,
    this.modeloCam,
    this.localEmp,
    this.dataHora,
    this.idSolucao,
    this.resolucao,
    this.numSerial,
    this.codvalidacao,
    this.diasgravacao,
    this.timezone,
    this.configRefreshSec,
    this.statusIA,
    this.provedor,
    this.protocolo,
    this.rtspExterno,
    this.usuario,
    this.senha,
    this.host,
    this.porta,
    this.caminho,
    this.servidor,
    this.idCameraP2p,
    this.entradaSaida,
    this.agentEnabled,
    this.confMin,
    this.conformityInterval,
    this.cooldownMin,
    this.displayClasses,
    this.requiredPpe,
    this.roiJson,
    this.vmsJson,
    this.lastSeen,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert any value to String
    String? toStringOrNull(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    return Camera(
      id: int.tryParse(json['id'].toString()) ?? 0,
      cameraId: json['camera_id'] != null
          ? int.tryParse(json['camera_id'].toString())
          : null,
      nomeCamera: json['NomeCamera'] as String? ?? '',
      linkcamera: json['linkcamera'] as String? ?? '',
      linkHLS: json['linkHLS'] as String? ?? '',
      tipoConexao: int.tryParse((json['Tipoconexao'] ??
              json['tipo_conexao'] ??
              json['tipoConexao'] ??
              json['protocolo'] ??
              '0')
          .toString()) ??
          0,
      idCliente: int.tryParse((json['idCliente'] ?? json['client_id'] ?? '0').toString()) ?? 0,
      gravar: json['gravar'] as int? ?? 0,
      enabled: json['enabled'] as int? ?? 1,
      localizacao: toStringOrNull(json['Localizacao']),
      endCam: toStringOrNull(json['EndCam']),
      modeloCam: toStringOrNull(json['modeloCam']),
      localEmp: toStringOrNull(json['localEmp']),
      dataHora: toStringOrNull(json['dataHora']),
      idSolucao: json['idSolucao'] as int?,
      resolucao: toStringOrNull(json['resolucao']),
      numSerial: toStringOrNull(json['numSerial']),
      codvalidacao: toStringOrNull(json['codvalidacao']),
      diasgravacao: json['diasgravacao'] as int?,
      timezone: toStringOrNull(json['timezone']),
      configRefreshSec: json['config_refresh_sec'] as int?,
      statusIA: json['statusIA'] as int?,
      provedor: toStringOrNull(json['provedor']),
      protocolo: json['protocolo'] as int?,
      rtspExterno: json['rtspExterno'] as int?,
      usuario: toStringOrNull(json['usuario']),
      senha: toStringOrNull(json['senha']),
      host: toStringOrNull(json['host']),
      porta: toStringOrNull(json['porta']),
      caminho: toStringOrNull(json['caminho']),
      servidor: toStringOrNull(json['servidor']),
      idCameraP2p: json['idCameraP2p'] as int?,
      entradaSaida: json['entradaSaida'] as int?,
      agentEnabled: json['agent_enabled'] as int?,
      confMin: (json['conf_min'] as num?)?.toDouble(),
      conformityInterval: json['conformity_interval'] as int?,
      cooldownMin: json['cooldown_min'] as int?,
      displayClasses: toStringOrNull(json['display_classes']),
      requiredPpe: toStringOrNull(json['required_ppe']),
      roiJson: toStringOrNull(json['roi_json']),
      vmsJson: toStringOrNull(json['vms_json']),
      lastSeen: toStringOrNull(json['last_seen']),
    );
  }

  /// Get the effective camera ID (camera_id if present, else id)
  int get displayId => cameraId ?? id;

  /// Get the VMS path name (idCliente/idCamera) for recordings
  String get vmsPathName => '$idCliente/$id';

  /// Check if camera has HLS stream available
  bool get hasHLSStream => linkHLS.trim().isNotEmpty;

  /// Check if camera has RTSP stream available
  bool get hasRTSPStream => linkcamera.trim().isNotEmpty;
}
