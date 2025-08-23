import 'package:cloud_firestore/cloud_firestore.dart';

class Cliente {
  final int? id; // Mantener para compatibilidad con versiones anteriores
  final String? firestoreId; // ID de Firestore
  final String numeroCliente;
  final String email;
  final String telefono;
  final String direccion;
  final String nombre;
  final double montoTotal;
  final int numeroCuotas;
  final DateTime fechaInicio;
  final double montoPrimeraCuota; // Entrega de materiales
  final String? observaciones; // Observaciones del cliente
  final bool activo;

  Cliente({
    this.id,
    this.firestoreId,
    required this.numeroCliente,
    required this.email,
    required this.telefono,
    required this.direccion,
    required this.nombre,
    required this.montoTotal,
    required this.numeroCuotas,
    required this.fechaInicio,
    required this.montoPrimeraCuota,
    this.observaciones,
    this.activo = true,
  });

  // Método para convertir a Map (Shared Preferences - retrocompatibilidad)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroCliente': numeroCliente,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'nombre': nombre,
      'montoTotal': montoTotal,
      'numeroCuotas': numeroCuotas,
      'fechaInicio': fechaInicio.millisecondsSinceEpoch,
      'montoPrimeraCuota': montoPrimeraCuota,
      'observaciones': observaciones,
      'activo': activo ? 1 : 0,
    };
  }

  // Método para convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'numeroCliente': numeroCliente,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'nombre': nombre,
      'montoTotal': montoTotal,
      'numeroCuotas': numeroCuotas,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'montoPrimeraCuota': montoPrimeraCuota,
      'observaciones': observaciones,
      'activo': activo,
      'fechaCreacion': FieldValue.serverTimestamp(),
    };
  }

  // Factory para crear desde Map (Shared Preferences - retrocompatibilidad)
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      numeroCliente: map['numeroCliente'],
      email: map['email'],
      telefono: map['telefono'],
      direccion: map['direccion'],
      nombre: map['nombre'],
      montoTotal: map['montoTotal']?.toDouble() ?? 0.0,
      numeroCuotas: map['numeroCuotas'] ?? 0,
      fechaInicio: DateTime.fromMillisecondsSinceEpoch(map['fechaInicio']),
      montoPrimeraCuota: map['montoPrimeraCuota']?.toDouble() ?? 0.0,
      observaciones: map['observaciones'],
      activo: map['activo'] == 1,
    );
  }

  // Factory para crear desde Firestore
  factory Cliente.fromFirestore(Map<String, dynamic> data, String documentId) {
    print('📋 ===== Cliente.fromFirestore =====');
    print('📋 DocumentId recibido: $documentId');
    print('📋 Data recibida: $data');
    
    final cliente = Cliente(
      firestoreId: documentId,
      numeroCliente: data['numeroCliente'] ?? '',
      email: data['email'] ?? '',
      telefono: data['telefono'] ?? '',
      direccion: data['direccion'] ?? '',
      nombre: data['nombre'] ?? '',
      montoTotal: (data['montoTotal'] ?? 0).toDouble(),
      numeroCuotas: data['numeroCuotas'] ?? 0,
      fechaInicio: data['fechaInicio'] is Timestamp
          ? (data['fechaInicio'] as Timestamp).toDate()
          : DateTime.now(),
      montoPrimeraCuota: (data['montoPrimeraCuota'] ?? 0).toDouble(),
      observaciones: data['observaciones'],
      activo: data['activo'] ?? true,
    );
    
    print('📋 Cliente creado - FirestoreId asignado: ${cliente.firestoreId}');
    print('📋 ===== fromFirestore COMPLETADO =====');
    return cliente;
  }

  Cliente copyWith({
    int? id,
    String? firestoreId,
    String? numeroCliente,
    String? email,
    String? telefono,
    String? direccion,
    String? nombre,
    double? montoTotal,
    int? numeroCuotas,
    DateTime? fechaInicio,
    double? montoPrimeraCuota,
    String? observaciones,
    bool? activo,
  }) {
    return Cliente(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      numeroCliente: numeroCliente ?? this.numeroCliente,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      nombre: nombre ?? this.nombre,
      montoTotal: montoTotal ?? this.montoTotal,
      numeroCuotas: numeroCuotas ?? this.numeroCuotas,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      montoPrimeraCuota: montoPrimeraCuota ?? this.montoPrimeraCuota,
      observaciones: observaciones ?? this.observaciones,
      activo: activo ?? this.activo,
    );
  }
}
