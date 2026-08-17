class SolucaoEquipamento {
  final int? id;
  final int? idEquipamentoIoT;
  final int idCliente;
  final int idSolucao;
  final String? dataHora;
  final int? enabled;

  SolucaoEquipamento({
    this.id,
    this.idEquipamentoIoT,
    required this.idCliente,
    required this.idSolucao,
    this.dataHora,
    this.enabled,
  });

  factory SolucaoEquipamento.fromJson(Map<String, dynamic> json) {
    return SolucaoEquipamento(
      id: int.tryParse(json['id']?.toString() ?? ''),
      idEquipamentoIoT: int.tryParse(json['idEquipamentoIoT']?.toString() ?? ''),
      idCliente: int.tryParse(json['idCliente']?.toString() ?? '') ?? 0,
      idSolucao: int.tryParse(json['idSolucao']?.toString() ?? '') ?? 0,
      dataHora: json['dataHora'] as String?,
      enabled: int.tryParse(json['enabled']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (idEquipamentoIoT != null) 'idEquipamentoIoT': idEquipamentoIoT,
      'idCliente': idCliente,
      'idSolucao': idSolucao,
      if (dataHora != null) 'dataHora': dataHora,
      if (enabled != null) 'enabled': enabled,
    };
  }
}

class EquipamentoIot {
  final int? id;
  final String nomeEquipamento;
  final String? enderecoInstalacao;
  final String? modeloEquipamento;
  final String? localizacao;
  final String? ipEquipamento;
  final String? localEmp;
  final int? tipoConexao;
  final int idCliente;
  final String? dataHora;
  final int? gravar;
  final String? resolucao;
  final String? imei;
  final String? prefix;
  final int? diasgravacao;
  final int? enabled;
  final String? timezone;
  final String? scheduleJson;
  final int? configRefreshSec;
  final int? statusIA;
  final int? idEquipamentoP2p;
  final int? idRasp;
  final List<SolucaoEquipamento>? solucoes;
  final List<int>? idSolucoes;
  final String? nomeCliente;

  EquipamentoIot({
    this.id,
    required this.nomeEquipamento,
    this.enderecoInstalacao,
    this.modeloEquipamento,
    this.localizacao,
    this.ipEquipamento,
    this.localEmp,
    this.tipoConexao,
    required this.idCliente,
    this.dataHora,
    this.gravar,
    this.resolucao,
    this.imei,
    this.prefix,
    this.diasgravacao,
    this.enabled,
    this.timezone,
    this.scheduleJson,
    this.configRefreshSec,
    this.statusIA,
    this.idEquipamentoP2p,
    this.idRasp,
    this.solucoes,
    this.idSolucoes,
    this.nomeCliente,
  });

  bool get isAtivo => (enabled ?? 0) == 1;

  factory EquipamentoIot.fromJson(Map<String, dynamic> json) {
    List<SolucaoEquipamento>? parsedSolucoes;
    if (json['solucoes'] is List) {
      parsedSolucoes = (json['solucoes'] as List)
          .map((s) => SolucaoEquipamento.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    List<int>? parsedIdSolucoes;
    if (json['idSolucoes'] is List) {
      parsedIdSolucoes = (json['idSolucoes'] as List)
          .map((item) => int.tryParse(item.toString()) ?? 0)
          .where((item) => item > 0)
          .toList();
    }

    return EquipamentoIot(
      id: int.tryParse(json['id']?.toString() ?? ''),
      nomeEquipamento: json['nomeEquipamento'] as String? ?? 'Sem Nome',
      enderecoInstalacao: json['enderecoInstalacao'] as String?,
      modeloEquipamento: json['modeloEquipamento'] as String?,
      localizacao: json['localizacao'] as String?,
      ipEquipamento: json['ipEquipamento'] as String?,
      localEmp: json['localEmp'] as String?,
      tipoConexao: int.tryParse(json['tipoConexao']?.toString() ?? ''),
      idCliente: int.tryParse(json['idCliente']?.toString() ?? '') ?? 0,
      dataHora: json['dataHora'] as String?,
      gravar: int.tryParse(json['gravar']?.toString() ?? ''),
      resolucao: json['resolucao'] as String?,
      imei: json['imei'] as String?,
      prefix: json['prefix'] as String?,
      diasgravacao: int.tryParse(json['diasgravacao']?.toString() ?? ''),
      enabled: int.tryParse(json['enabled']?.toString() ?? '') ?? 1,
      timezone: json['timezone'] as String?,
      scheduleJson: json['schedule_json'] as String?,
      configRefreshSec: int.tryParse(json['config_refresh_sec']?.toString() ?? ''),
      statusIA: int.tryParse(json['statusIA']?.toString() ?? ''),
      idEquipamentoP2p: int.tryParse(json['idEquipamentoP2p']?.toString() ?? ''),
      idRasp: int.tryParse(json['idRasp']?.toString() ?? ''),
      solucoes: parsedSolucoes,
      idSolucoes: parsedIdSolucoes,
      nomeCliente: json['nomeCliente'] as String?,
    );
  }

  EquipamentoIot copyWith({
    int? id,
    String? nomeEquipamento,
    String? enderecoInstalacao,
    String? modeloEquipamento,
    String? localizacao,
    String? ipEquipamento,
    String? localEmp,
    int? tipoConexao,
    int? idCliente,
    String? dataHora,
    int? gravar,
    String? resolucao,
    String? imei,
    String? prefix,
    int? diasgravacao,
    int? enabled,
    String? timezone,
    String? scheduleJson,
    int? configRefreshSec,
    int? statusIA,
    int? idEquipamentoP2p,
    int? idRasp,
    List<SolucaoEquipamento>? solucoes,
    List<int>? idSolucoes,
    String? nomeCliente,
  }) {
    return EquipamentoIot(
      id: id ?? this.id,
      nomeEquipamento: nomeEquipamento ?? this.nomeEquipamento,
      enderecoInstalacao: enderecoInstalacao ?? this.enderecoInstalacao,
      modeloEquipamento: modeloEquipamento ?? this.modeloEquipamento,
      localizacao: localizacao ?? this.localizacao,
      ipEquipamento: ipEquipamento ?? this.ipEquipamento,
      localEmp: localEmp ?? this.localEmp,
      tipoConexao: tipoConexao ?? this.tipoConexao,
      idCliente: idCliente ?? this.idCliente,
      dataHora: dataHora ?? this.dataHora,
      gravar: gravar ?? this.gravar,
      resolucao: resolucao ?? this.resolucao,
      imei: imei ?? this.imei,
      prefix: prefix ?? this.prefix,
      diasgravacao: diasgravacao ?? this.diasgravacao,
      enabled: enabled ?? this.enabled,
      timezone: timezone ?? this.timezone,
      scheduleJson: scheduleJson ?? this.scheduleJson,
      configRefreshSec: configRefreshSec ?? this.configRefreshSec,
      statusIA: statusIA ?? this.statusIA,
      idEquipamentoP2p: idEquipamentoP2p ?? this.idEquipamentoP2p,
      idRasp: idRasp ?? this.idRasp,
      solucoes: solucoes ?? this.solucoes,
      idSolucoes: idSolucoes ?? this.idSolucoes,
      nomeCliente: nomeCliente ?? this.nomeCliente,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nomeEquipamento': nomeEquipamento,
      if (enderecoInstalacao != null) 'enderecoInstalacao': enderecoInstalacao,
      if (modeloEquipamento != null) 'modeloEquipamento': modeloEquipamento,
      if (localizacao != null) 'localizacao': localizacao,
      if (ipEquipamento != null) 'ipEquipamento': ipEquipamento,
      if (localEmp != null) 'localEmp': localEmp,
      if (tipoConexao != null) 'tipoConexao': tipoConexao,
      'idCliente': idCliente,
      if (dataHora != null) 'dataHora': dataHora,
      if (gravar != null) 'gravar': gravar,
      if (resolucao != null) 'resolucao': resolucao,
      if (imei != null) 'imei': imei,
      if (prefix != null) 'prefix': prefix,
      if (diasgravacao != null) 'diasgravacao': diasgravacao,
      if (enabled != null) 'enabled': enabled,
      if (timezone != null) 'timezone': timezone,
      if (scheduleJson != null) 'schedule_json': scheduleJson,
      if (configRefreshSec != null) 'config_refresh_sec': configRefreshSec,
      if (statusIA != null) 'statusIA': statusIA,
      if (idEquipamentoP2p != null) 'idEquipamentoP2p': idEquipamentoP2p,
      if (idRasp != null) 'idRasp': idRasp,
      if (solucoes != null) 'solucoes': solucoes!.map((s) => s.toJson()).toList(),
      if (idSolucoes != null) 'idSolucoes': idSolucoes,
      if (nomeCliente != null) 'nomeCliente': nomeCliente,
    };
  }
}
