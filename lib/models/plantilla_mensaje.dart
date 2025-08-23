import 'package:cloud_firestore/cloud_firestore.dart';

class PlantillaMensaje {
  final int? id; // Mantener para compatibilidad con versiones anteriores
  final String? firestoreId; // ID de Firestore
  final String nombre;
  final String mensaje;
  final TipoMensaje tipo;
  final bool activa;
  final int? iconCodePoint; // Código del icono seleccionado

  PlantillaMensaje({
    this.id,
    this.firestoreId,
    required this.nombre,
    required this.mensaje,
    required this.tipo,
    this.activa = true,
    this.iconCodePoint,
  });

  // Método para convertir a Map (Shared Preferences - retrocompatibilidad)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'mensaje': mensaje,
      'tipo': tipo.index,
      'activa': activa ? 1 : 0,
      'iconCodePoint': iconCodePoint,
    };
  }

  // Método para convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'mensaje': mensaje,
      'tipo': tipo.name, // Usar el nombre del enum en lugar del índice
      'activa': activa,
      'iconCodePoint': iconCodePoint,
      'fechaCreacion': FieldValue.serverTimestamp(),
    };
  }

  // Factory para crear desde Map (Shared Preferences - retrocompatibilidad)
  factory PlantillaMensaje.fromMap(Map<String, dynamic> map) {
    return PlantillaMensaje(
      id: map['id'],
      nombre: map['nombre'] ?? '',
      mensaje: map['mensaje'] ?? '',
      tipo: TipoMensaje.values[map['tipo'] ?? 0],
      activa: map['activa'] == 1,
      iconCodePoint: map['iconCodePoint'],
    );
  }

  // Factory para crear desde Firestore
  factory PlantillaMensaje.fromFirestore(Map<String, dynamic> data, String documentId) {
    return PlantillaMensaje(
      firestoreId: documentId,
      nombre: data['nombre'] ?? '',
      mensaje: data['mensaje'] ?? '',
      tipo: _tipoMensajeFromString(data['tipo'] ?? 'recordatorioPago'),
      activa: data['activa'] ?? true,
      iconCodePoint: data['iconCodePoint'],
    );
  }

  // Función auxiliar para convertir string a TipoMensaje
  static TipoMensaje _tipoMensajeFromString(String tipoString) {
    try {
      return TipoMensaje.values.firstWhere((tipo) => tipo.name == tipoString);
    } catch (e) {
      return TipoMensaje.recordatorioPago; // Valor por defecto
    }
  }

  PlantillaMensaje copyWith({
    int? id,
    String? firestoreId,
    String? nombre,
    String? mensaje,
    TipoMensaje? tipo,
    bool? activa,
    int? iconCodePoint,
  }) {
    return PlantillaMensaje(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      nombre: nombre ?? this.nombre,
      mensaje: mensaje ?? this.mensaje,
      tipo: tipo ?? this.tipo,
      activa: activa ?? this.activa,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }
}

enum TipoMensaje {
  recordatorioPago,
  pagoVencido,
  proximoVencimiento,
  primeraCuota,
  personalizada, // Nueva opción para plantillas personalizadas
}

extension TipoMensajeExtension on TipoMensaje {
  String get descripcion {
    switch (this) {
      case TipoMensaje.recordatorioPago:
        return 'Recordatorio de Pago';
      case TipoMensaje.pagoVencido:
        return 'Pago Vencido';
      case TipoMensaje.proximoVencimiento:
        return 'Próximo Vencimiento';
      case TipoMensaje.primeraCuota:
        return 'Primera Cuota - Entrega de Materiales';
      case TipoMensaje.personalizada:
        return 'Plantilla Personalizada';
    }
  }
}
