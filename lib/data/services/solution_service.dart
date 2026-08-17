import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensortech/data/models/solution_model.dart';

class SolucaoColorInfo {
  final Color bg;
  final Color text;
  const SolucaoColorInfo({required this.bg, required this.text});
}

/// Service for fetching solutions from the /api/v1/soluction endpoint.
class SolutionService {
  final Dio _dio;

  SolutionService(this._dio);

  /// Fetch all solutions from the backend.
  Future<List<Solution>> list() async {
    try {
      final response = await _dio.get('/api/v1/soluction');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> solutionList;

        if (data is List) {
          solutionList = data;
        } else if (data is Map && data['data'] != null) {
          solutionList = data['data'] as List;
        } else {
          return [];
        }

        return solutionList
            .map((json) => Solution.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SolutionService] Error fetching solutions: $e');
      }
      rethrow;
    }
  }

  /// Fetch a single solution by ID.
  Future<Solution?> getById(int id) async {
    try {
      final response = await _dio.get('/api/v1/soluction/$id');

      if (response.statusCode == 200 && response.data != null) {
        return Solution.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SolutionService] Error fetching solution $id: $e');
      }
      rethrow;
    }
  }

  /// Get the label for a solution by its ID from a pre-fetched list.
  static String getLabelFromList(List<Solution> solutions, int? idSolucao) {
    if (idSolucao == null) return '';
    final sol = solutions.where((s) => s.id == idSolucao).firstOrNull;
    return sol?.label ?? 'Solução $idSolucao';
  }

  static const List<SolucaoColorInfo> badgeColors = [
    SolucaoColorInfo(bg: Color(0xFF0d9488), text: Color(0xFFffffff)), // teal
    SolucaoColorInfo(bg: Color(0xFF16a34a), text: Color(0xFFffffff)), // green
    SolucaoColorInfo(bg: Color(0xFF2563eb), text: Color(0xFFffffff)), // blue
    SolucaoColorInfo(bg: Color(0xFF7c3aed), text: Color(0xFFffffff)), // purple
    SolucaoColorInfo(bg: Color(0xFFdb2777), text: Color(0xFFffffff)), // pink
    SolucaoColorInfo(bg: Color(0xFFd97706), text: Color(0xFFffffff)), // amber
    SolucaoColorInfo(bg: Color(0xFFdc2626), text: Color(0xFFffffff)), // red
    SolucaoColorInfo(bg: Color(0xFF0891b2), text: Color(0xFFffffff)), // cyan
    SolucaoColorInfo(bg: Color(0xFF65a30d), text: Color(0xFFffffff)), // lime
    SolucaoColorInfo(bg: Color(0xFF9333ea), text: Color(0xFFffffff)), // violet
  ];

  /// Cor determinística baseada no índice da paleta
  static SolucaoColorInfo getColor(int idSolucao) {
    return badgeColors[idSolucao % badgeColors.length];
  }
}
