/// Extended client model with full details from /api/v1/clientes endpoint
class ClienteDetailed {
  final int id;
  final String cnpj;
  final String razaoSocial;
  final String? nomeFantasia;
  final String? telefone;
  final String? email;
  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? dataCadastro;
  final List<int> solucoes;

  ClienteDetailed({
    required this.id,
    required this.cnpj,
    required this.razaoSocial,
    this.nomeFantasia,
    this.telefone,
    this.email,
    this.cep,
    this.logradouro,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.dataCadastro,
    required this.solucoes,
  });

  /// Get display name (prefer nomeFantasia over razaoSocial)
  String get displayName =>
      (nomeFantasia != null && nomeFantasia!.trim().isNotEmpty)
          ? nomeFantasia!
          : razaoSocial;

  factory ClienteDetailed.fromJson(Map<String, dynamic> json) {
    List<int> solucoesIds = [];
    if (json['solucoes'] != null) {
      final solucoesList = json['solucoes'] as List;
      solucoesIds = solucoesList
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((id) => id > 0)
          .toList();
    }

    return ClienteDetailed(
      id: int.tryParse(json['id'].toString()) ?? 0,
      cnpj: json['cnpj'] as String? ?? '',
      razaoSocial: json['razaoSocial'] as String? ?? '',
      nomeFantasia: json['nomeFantasia'] as String?,
      telefone: json['telefone'] as String?,
      email: json['email'] as String?,
      cep: json['cep'] as String?,
      logradouro: json['logradouro'] as String?,
      numero: json['numero'] as String?,
      bairro: json['bairro'] as String?,
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
      dataCadastro: json['dataCadastro'] as String?,
      solucoes: solucoesIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cnpj': cnpj,
      'razaoSocial': razaoSocial,
      if (nomeFantasia != null) 'nomeFantasia': nomeFantasia,
      if (telefone != null) 'telefone': telefone,
      if (email != null) 'email': email,
      if (cep != null) 'cep': cep,
      if (logradouro != null) 'logradouro': logradouro,
      if (numero != null) 'numero': numero,
      if (bairro != null) 'bairro': bairro,
      if (cidade != null) 'cidade': cidade,
      if (estado != null) 'estado': estado,
      if (dataCadastro != null) 'dataCadastro': dataCadastro,
      'solucoes': solucoes,
    };
  }
}
