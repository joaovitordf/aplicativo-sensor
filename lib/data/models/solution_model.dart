/// Represents a class detected by an AI model (e.g., helmet, vest, mask).
class ModeloClasse {
  final int id;
  final String status;
  final String className;
  final int classIndex;

  ModeloClasse({
    required this.id,
    required this.status,
    required this.className,
    required this.classIndex,
  });

  factory ModeloClasse.fromJson(Map<String, dynamic> json) {
    return ModeloClasse(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      className: json['className'] as String? ?? '',
      classIndex: json['classIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'className': className,
      'classIndex': classIndex,
    };
  }
}

/// Represents an AI model configuration.
class ModeloIA {
  final int id;
  final String nomeObjeto;
  final String modeloVersao;
  final String status;
  final String arquivoNome;
  final List<ModeloClasse> classes;

  ModeloIA({
    required this.id,
    required this.nomeObjeto,
    required this.modeloVersao,
    required this.status,
    required this.arquivoNome,
    required this.classes,
  });

  factory ModeloIA.fromJson(Map<String, dynamic> json) {
    return ModeloIA(
      id: json['id'] as int? ?? 0,
      nomeObjeto: json['nomeObjeto'] as String? ?? '',
      modeloVersao: json['modeloVersao'] as String? ?? '',
      status: json['status'] as String? ?? '',
      arquivoNome: json['arquivoNome'] as String? ?? '',
      classes: (json['classes'] as List?)
              ?.map((item) =>
                  ModeloClasse.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeObjeto': nomeObjeto,
      'modeloVersao': modeloVersao,
      'status': status,
      'arquivoNome': arquivoNome,
      'classes': classes.map((c) => c.toJson()).toList(),
    };
  }
}

/// Represents a solution from the /api/v1/soluction endpoint.
class Solution {
  final int id;
  final String label;
  final int usaIA; // 0 or 1
  final int? idModeloIA;
  final ModeloIA? modelo;

  Solution({
    required this.id,
    required this.label,
    required this.usaIA,
    this.idModeloIA,
    this.modelo,
  });

  /// Whether this solution uses AI detection.
  bool get usesAI => usaIA == 1;

  factory Solution.fromJson(Map<String, dynamic> json) {
    return Solution(
      id: json['id'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      usaIA: json['usaIA'] as int? ?? 0,
      idModeloIA: json['idModeloIA'] as int?,
      modelo: json['modelo'] != null
          ? ModeloIA.fromJson(json['modelo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'usaIA': usaIA,
      if (idModeloIA != null) 'idModeloIA': idModeloIA,
      if (modelo != null) 'modelo': modelo?.toJson(),
    };
  }
}
