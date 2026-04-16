import 'dart:convert';

import 'package:flutter/foundation.dart';
part 'debugger.dart';

enum DebugLabel {
  ui("UI"),
  controller("Controller"),
  service("Service"),
  auth("Auth"),
  setting("Setting"),
  notification("Notification"),
  audio("Audio");

  final String label;

  const DebugLabel(this.label);
}

class DebugService {
  final Set<DebugLabel> _allowsOnly;

  DebugService._(this._allowsOnly);

  static DebugService? _instance;

  /// Singletone
  factory DebugService.instance({required Set<DebugLabel> allowsOnly}) {
    _instance ??= DebugService._(allowsOnly);
    return _instance!;
  }

  void dekhao(DebugLabel label, dynamic data) {
    if (!_allowsOnly.contains(label)) return;
    // Print, only if the debug label is present in the _allowOnly list.
    if (kDebugMode) {
      final prefix = "Debug >> ${label.label} >>";
      final formattedData = _formatDebugData(data);
      if (formattedData.contains('\n')) {
        _printDebugChunks("$prefix\n$formattedData");
      } else {
        _printDebugChunks("$prefix $formattedData");
      }
    }
  }
}

String _formatDebugData(dynamic data) {
  if (data == null) return 'null';

  dynamic normalized = data;
  if (data is String) {
    final source = data.trim();
    if (_looksLikeJson(source)) {
      try {
        normalized = jsonDecode(source);
      } catch (_) {
        return data;
      }
    } else {
      return data;
    }
  }

  normalized = _normalizeForJson(normalized);
  try {
    return const JsonEncoder.withIndent('  ').convert(normalized);
  } catch (_) {
    return normalized.toString();
  }
}

dynamic _normalizeForJson(dynamic value) {
  if (value == null || value is num || value is bool || value is String) {
    return value;
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), _normalizeForJson(val)),
    );
  }
  if (value is Iterable) {
    return value.map(_normalizeForJson).toList();
  }
  return value.toString();
}

bool _looksLikeJson(String source) {
  return (source.startsWith('{') && source.endsWith('}')) ||
      (source.startsWith('[') && source.endsWith(']'));
}

void _printDebugChunks(String message, {int chunkSize = 900}) {
  final lines = message.split('\n');
  for (final line in lines) {
    if (line.length <= chunkSize) {
      debugPrint(line);
      continue;
    }
    for (var start = 0; start < line.length; start += chunkSize) {
      final end = (start + chunkSize < line.length)
          ? start + chunkSize
          : line.length;
      debugPrint(line.substring(start, end));
    }
  }
}
