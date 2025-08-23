import 'package:cloud_firestore/cloud_firestore.dart';

class Cuota {
  final int? id; // Mantener para compatibilidad con versiones anteriores
  final String? firestoreId; // ID de Firestore
  final String clienteId; // Ahora es String para Firestore ID
  final int numeroCuota;
  final double monto;
  final DateTime fechaVencimiento;
  final bool pagada;
  final DateTime? fechaPago;
  final String? observaciones;
  final bool activo; // Para soft delete

  Cuota({
    this.id,
    this.firestoreId,
    required this.clienteId,
    required this.numeroCuota,
    required this.monto,
    required this.fechaVencimiento,
    this.pagada = false,
    this.fechaPago,
    this.observaciones,
    this.activo = true,
  });

  // Método para convertir a Map (Shared Preferences - retrocompatibilidad)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clienteId': clienteId,
      'numeroCuota': numeroCuota,
      'monto': monto,
      'fechaVencimiento': fechaVencimiento.millisecondsSinceEpoch,
      'pagada': pagada ? 1 : 0,
      'fechaPago': fechaPago?.millisecondsSinceEpoch,
      'observaciones': observaciones,
    };
  }

  // Método para convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'clienteId': clienteId,
      'numeroCuota': numeroCuota,
      'monto': monto,
      'fechaVencimiento': Timestamp.fromDate(fechaVencimiento),
      'pagada': pagada,
      'fechaPago': fechaPago != null ? Timestamp.fromDate(fechaPago!) : null,
      'observaciones': observaciones,
      'activo': activo,
      'fechaCreacion': FieldValue.serverTimestamp(),
    };
  }

  // Factory para crear desde Map (Shared Preferences - retrocompatibilidad)
  factory Cuota.fromMap(Map<String, dynamic> map) {
    return Cuota(
      id: map['id'],
      clienteId: map['clienteId'].toString(), // Convertir a String
      numeroCuota: map['numeroCuota'],
      monto: map['monto']?.toDouble() ?? 0.0,
      fechaVencimiento: DateTime.fromMillisecondsSinceEpoch(
        map['fechaVencimiento'],
      ),
      pagada: map['pagada'] == 1,
      fechaPago: map['fechaPago'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fechaPago'])
          : null,
      observaciones: map['observaciones'],
    );
  }

  // Factory para crear desde Firestore
  factory Cuota.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Cuota(
      firestoreId: documentId,
      clienteId: data['clienteId'] ?? '',
      numeroCuota: data['numeroCuota'] ?? 0,
      monto: (data['monto'] ?? 0).toDouble(),
      fechaVencimiento: data['fechaVencimiento'] is Timestamp
          ? (data['fechaVencimiento'] as Timestamp).toDate()
          : DateTime.now(),
      pagada: data['pagada'] ?? false,
      fechaPago: data['fechaPago'] is Timestamp
          ? (data['fechaPago'] as Timestamp).toDate()
          : null,
      observaciones: data['observaciones'],
      activo: data['activo'] ?? true,
    );
  }

  Cuota copyWith({
    int? id,
    String? firestoreId,
    String? clienteId,
    int? numeroCuota,
    double? monto,
    DateTime? fechaVencimiento,
    bool? pagada,
    DateTime? fechaPago,
    String? observaciones,
    bool? activo,
  }) {
    return Cuota(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      clienteId: clienteId ?? this.clienteId,
      numeroCuota: numeroCuota ?? this.numeroCuota,
      monto: monto ?? this.monto,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      pagada: pagada ?? this.pagada,
      fechaPago: fechaPago ?? this.fechaPago,
      observaciones: observaciones ?? this.observaciones,
      activo: activo ?? this.activo,
    );
  }

  bool get estaVencida {
    return !pagada && DateTime.now().isAfter(fechaVencimiento);
  }

  bool get venceProximamente {
    final ahora = DateTime.now();
    final diferencia = fechaVencimiento.difference(ahora).inDays;
    return !pagada && diferencia >= 0 && diferencia <= 30;
  }
}
