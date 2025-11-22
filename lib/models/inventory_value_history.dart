/// Modelo para representar un punto de datos históricos del valor del inventario
class InventoryValuePoint {
  final DateTime date;
  final double value;

  InventoryValuePoint({
    required this.date,
    required this.value,
  });

  /// Crear desde JSON
  factory InventoryValuePoint.fromJson(Map<String, dynamic> json) {
    return InventoryValuePoint(
      date: DateTime.parse(json['date'] ?? json['fecha'] ?? DateTime.now().toIso8601String()),
      value: (json['value'] ?? json['valor'] ?? 0.0).toDouble(),
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
    };
  }
}

/// Enum para los períodos de tiempo
enum TimePeriod {
  day,
  week,
  month,
  year,
}

