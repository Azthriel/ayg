import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente.dart';
import '../models/cuota.dart';
import '../models/plantilla_mensaje.dart';

/// Servicio de almacenamiento usando Cloud Firestore
/// Proporciona sincronización en tiempo real y almacenamiento en la nube
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referencias a las colecciones
  CollectionReference get _clientesCollection =>
      _firestore.collection('clientes');
  CollectionReference get _cuotasCollection => _firestore.collection('cuotas');
  CollectionReference get _plantillasCollection =>
      _firestore.collection('plantillas');

  // ===== MÉTODOS PARA CLIENTES =====

  /// Obtiene todos los clientes activos (versión sin índice compuesto)
  Future<List<Cliente>> getClientes() async {
    print('🔥 ===== getClientes INICIADO =====');
    try {
      print('🔥 Ejecutando query en Firestore...');
      final querySnapshot = await _clientesCollection
          .where('activo', isEqualTo: true)
          .get();

      print('🔥 Documentos encontrados: ${querySnapshot.docs.length}');

      final clientes = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('🔥 Documento ID: ${doc.id}');
        print('🔥 Datos del documento: $data');

        final cliente = Cliente.fromFirestore(data, doc.id);
        print(
          '🔥 Cliente creado - Nombre: ${cliente.nombre}, FirestoreId: ${cliente.firestoreId}',
        );

        return cliente;
      }).toList();

      // Ordenar por nombre en el cliente
      clientes.sort((a, b) => a.nombre.compareTo(b.nombre));

      print(
        '🔥 ===== getClientes COMPLETADO - ${clientes.length} clientes =====',
      );
      return clientes;
    } catch (e) {
      print('🔥 ❌ ERROR en getClientes: $e');
      return [];
    }
  }

  /// Obtiene un stream de clientes para actualizaciones en tiempo real (versión sin índice compuesto)
  Stream<List<Cliente>> getClientesStream() {
    return _clientesCollection.where('activo', isEqualTo: true).snapshots().map(
      (snapshot) {
        final clientes = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Cliente.fromFirestore(data, doc.id);
        }).toList();

        // Ordenar por nombre en el cliente
        clientes.sort((a, b) => a.nombre.compareTo(b.nombre));
        return clientes;
      },
    );
  }

  /// Inserta un nuevo cliente
  Future<String?> insertCliente(Cliente cliente) async {
    try {
      final docRef = await _clientesCollection.add(cliente.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error insertando cliente: $e');
      return null;
    }
  }

  /// Actualiza un cliente existente
  Future<bool> updateCliente(Cliente cliente) async {
    print('🔥 ===== FirestoreService.updateCliente INICIADO =====');
    print('🔥 Cliente: ${cliente.nombre}');
    print('🔥 FirestoreId: ${cliente.firestoreId}');

    try {
      if (cliente.firestoreId == null) {
        print('🔥 ❌ ERROR: cliente.firestoreId es NULL');
        print('🔥 ===== RETORNANDO FALSE (firestoreId null) =====');
        return false;
      }

      print('🔥 Preparando datos para Firestore...');
      final datosFirestore = cliente.toFirestore();
      print('🔥 Datos a actualizar: $datosFirestore');

      print('🔥 Ejecutando actualización en Firestore...');
      await _clientesCollection.doc(cliente.firestoreId).update(datosFirestore);

      print('🔥 ✅ Cliente actualizado exitosamente en Firestore');
      print('🔥 ===== RETORNANDO TRUE =====');
      return true;
    } catch (e) {
      print('🔥 ❌ ERROR CRÍTICO actualizando cliente: $e');
      print('🔥 ❌ Tipo de error: ${e.runtimeType}');
      print('🔥 ===== RETORNANDO FALSE (excepción) =====');
      return false;
    }
  }

  /// Elimina un cliente (soft delete)
  Future<bool> deleteCliente(String clienteId) async {
    try {
      await _clientesCollection.doc(clienteId).update({'activo': false});

      // También marcar como inactivas todas las cuotas del cliente
      final cuotasQuery = await _cuotasCollection
          .where('clienteId', isEqualTo: clienteId)
          .get();

      final batch = _firestore.batch();
      for (var doc in cuotasQuery.docs) {
        batch.update(doc.reference, {'activo': false});
      }
      await batch.commit();

      return true;
    } catch (e) {
      print('Error eliminando cliente: $e');
      return false;
    }
  }

  /// Obtiene un cliente por su ID de Firestore
  Future<Cliente?> getClienteById(String firestoreId) async {
    try {
      final doc = await _clientesCollection.doc(firestoreId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Cliente.fromFirestore(data, doc.id);
      }
      return null;
    } catch (e) {
      print('Error obteniendo cliente por ID: $e');
      return null;
    }
  }

  /// Actualiza las observaciones de un cliente
  Future<bool> updateClienteObservaciones(
    String clienteId,
    String? observaciones,
  ) async {
    print('🔥 FirestoreService: Iniciando updateClienteObservaciones');
    print('🔥 ClienteId: $clienteId');
    print('🔥 Observaciones: ${observaciones ?? "null"}');

    try {
      print('🔥 Intentando actualizar documento en Firestore...');
      await _clientesCollection.doc(clienteId).update({
        'observaciones': observaciones,
      });
      print('🔥 ✅ Documento actualizado exitosamente en Firestore');
      return true;
    } catch (e) {
      print('🔥 ❌ ERROR CRÍTICO en updateClienteObservaciones: $e');
      print('🔥 ❌ Tipo de error: ${e.runtimeType}');
      print('🔥 ❌ Stack trace completo:');
      print(e);
      return false;
    }
  }

  /// Obtiene un cliente por su número de cliente
  Future<Cliente?> getClienteByNumero(String numeroCliente) async {
    try {
      final querySnapshot = await _clientesCollection
          .where('numeroCliente', isEqualTo: numeroCliente)
          .where('activo', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        return Cliente.fromFirestore(data, querySnapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      print('Error obteniendo cliente por número: $e');
      return null;
    }
  }

  // ===== MÉTODOS PARA CUOTAS =====

  /// Obtiene todas las cuotas (versión simple sin índices)
  Future<List<Cuota>> getAllCuotas() async {
    try {
      final querySnapshot = await _cuotasCollection
          .where('activo', isEqualTo: true)
          .get();

      final cuotas = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Cuota.fromFirestore(data, doc.id);
      }).toList();

      // Ordenar por fecha de vencimiento en el cliente
      cuotas.sort((a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento));

      return cuotas;
    } catch (e) {
      print('Error obteniendo todas las cuotas: $e');
      return [];
    }
  }

  /// Obtiene todas las cuotas (método original con orderBy - puede requerir índice)
  Future<List<Cuota>> getCuotas() async {
    try {
      final querySnapshot = await _cuotasCollection
          .where('activo', isEqualTo: true)
          .orderBy('fechaVencimiento')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Cuota.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error obteniendo cuotas: $e');
      return [];
    }
  }

  /// Obtiene las cuotas de un cliente específico
  Future<List<Cuota>> getCuotasByCliente(String clienteId) async {
    try {
      final querySnapshot = await _cuotasCollection
          .where('clienteId', isEqualTo: clienteId)
          .where('activo', isEqualTo: true)
          .orderBy('numeroCuota')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Cuota.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error obteniendo cuotas del cliente: $e');
      return [];
    }
  }

  /// Obtiene cuotas vencidas (versión sin índice compuesto)
  Future<List<Cuota>> getCuotasVencidas() async {
    try {
      final now = DateTime.now();
      // Primero obtener todas las cuotas activas y no pagadas
      final querySnapshot = await _cuotasCollection
          .where('activo', isEqualTo: true)
          .where('pagada', isEqualTo: false)
          .get();

      // Filtrar en el cliente las que están vencidas y ordenar
      final cuotasVencidas = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Cuota.fromFirestore(data, doc.id);
          })
          .where((cuota) => cuota.fechaVencimiento.isBefore(now))
          .toList();

      // Ordenar por fecha de vencimiento
      cuotasVencidas.sort(
        (a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento),
      );

      return cuotasVencidas;
    } catch (e) {
      print('Error obteniendo cuotas vencidas: $e');
      return [];
    }
  }

  /// Obtiene cuotas próximas a vencer (en los próximos 7 días) - versión sin índice compuesto
  Future<List<Cuota>> getCuotasProximasAVencer() async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      // Primero obtener todas las cuotas activas y no pagadas
      final querySnapshot = await _cuotasCollection
          .where('activo', isEqualTo: true)
          .where('pagada', isEqualTo: false)
          .get();

      // Filtrar en el cliente las que vencen en los próximos 7 días
      final cuotasProximas = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Cuota.fromFirestore(data, doc.id);
          })
          .where(
            (cuota) =>
                cuota.fechaVencimiento.isAfter(now) &&
                cuota.fechaVencimiento.isBefore(nextWeek),
          )
          .toList();

      // Ordenar por fecha de vencimiento
      cuotasProximas.sort(
        (a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento),
      );

      return cuotasProximas;
    } catch (e) {
      print('Error obteniendo cuotas próximas a vencer: $e');
      return [];
    }
  }

  /// Inserta una nueva cuota
  Future<String?> insertCuota(Cuota cuota) async {
    try {
      final docRef = await _cuotasCollection.add(cuota.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error insertando cuota: $e');
      return null;
    }
  }

  /// Actualiza una cuota existente
  Future<bool> updateCuota(Cuota cuota) async {
    try {
      if (cuota.firestoreId == null) return false;

      await _cuotasCollection
          .doc(cuota.firestoreId)
          .update(cuota.toFirestore());
      return true;
    } catch (e) {
      print('Error actualizando cuota: $e');
      return false;
    }
  }

  /// Elimina una cuota (soft delete)
  Future<bool> deleteCuota(String cuotaId) async {
    try {
      await _cuotasCollection.doc(cuotaId).update({'activo': false});
      return true;
    } catch (e) {
      print('Error eliminando cuota: $e');
      return false;
    }
  }

  /// Marca una cuota como pagada
  Future<bool> marcarCuotaComoPagada(
    String cuotaId,
    DateTime? fechaPago,
    String? observaciones,
  ) async {
    try {
      await _cuotasCollection.doc(cuotaId).update({
        'pagada': true,
        'fechaPago': fechaPago != null
            ? Timestamp.fromDate(fechaPago)
            : FieldValue.serverTimestamp(),
        'observaciones': observaciones,
      });
      return true;
    } catch (e) {
      print('Error marcando cuota como pagada: $e');
      return false;
    }
  }

  /// Genera cuotas para un cliente
  Future<bool> generarCuotasParaCliente(Cliente cliente) async {
    try {
      if (cliente.firestoreId == null) return false;

      final batch = _firestore.batch();

      // Generar las cuotas
      final cuotas = _calcularCuotas(cliente);

      for (var cuota in cuotas) {
        final cuotaDoc = _cuotasCollection.doc();
        batch.set(cuotaDoc, cuota.toFirestore());
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error generando cuotas: $e');
      return false;
    }
  }

  /// Regenera las cuotas de un cliente (elimina las existentes y crea nuevas)
  Future<bool> regenerarCuotasCliente(Cliente cliente) async {
    print('🔥 ===== regenerarCuotasCliente INICIADO =====');
    print('🔥 Cliente: ${cliente.nombre}');
    print('🔥 FirestoreId: ${cliente.firestoreId}');

    try {
      if (cliente.firestoreId == null) {
        print('🔥 ❌ ERROR: cliente.firestoreId es NULL');
        return false;
      }

      print('🔥 Buscando cuotas existentes...');
      // Primero eliminar cuotas existentes (soft delete)
      final cuotasExistentes = await _cuotasCollection
          .where('clienteId', isEqualTo: cliente.firestoreId)
          .get();

      print(
        '🔥 Cuotas existentes encontradas: ${cuotasExistentes.docs.length}',
      );

      final batch = _firestore.batch();

      // Marcar como inactivas las cuotas existentes
      for (var doc in cuotasExistentes.docs) {
        batch.update(doc.reference, {'activo': false});
      }
      print('🔥 ✅ Cuotas existentes marcadas como inactivas');

      print('🔥 Calculando nuevas cuotas...');
      // Generar nuevas cuotas
      final cuotas = _calcularCuotas(cliente);
      print('🔥 Nuevas cuotas calculadas: ${cuotas.length}');

      for (var cuota in cuotas) {
        final cuotaDoc = _cuotasCollection.doc();
        batch.set(cuotaDoc, cuota.toFirestore());
      }
      print('🔥 ✅ Nuevas cuotas agregadas al batch');

      print('🔥 Ejecutando batch commit...');
      await batch.commit();
      print('🔥 ✅ Cuotas regeneradas exitosamente');
      print('🔥 ===== regenerarCuotasCliente COMPLETADO =====');
      return true;
    } catch (e) {
      print('🔥 ❌ ERROR CRÍTICO en regenerarCuotasCliente: $e');
      print('🔥 ❌ Tipo de error: ${e.runtimeType}');
      return false;
    }
  }

  /// Calcula las cuotas de un cliente basándose en sus datos
  List<Cuota> _calcularCuotas(Cliente cliente) {
    final cuotas = <Cuota>[];
    final montoRestante = cliente.montoTotal - cliente.montoPrimeraCuota;
    final montoCuotaRegular = montoRestante / (cliente.numeroCuotas - 1);

    // Primera cuota (entrega de materiales)
    cuotas.add(
      Cuota(
        firestoreId: null,
        clienteId: cliente.firestoreId!,
        numeroCuota: 1,
        monto: cliente.montoPrimeraCuota,
        fechaVencimiento: cliente.fechaInicio,
        pagada: false,
        observaciones: 'Entrega de materiales',
      ),
    );

    // Cuotas restantes
    for (int i = 2; i <= cliente.numeroCuotas; i++) {
      final fechaVencimiento = DateTime(
        cliente.fechaInicio.year,
        cliente.fechaInicio.month + i - 1,
        cliente.fechaInicio.day,
      );

      cuotas.add(
        Cuota(
          firestoreId: null,
          clienteId: cliente.firestoreId!,
          numeroCuota: i,
          monto: montoCuotaRegular,
          fechaVencimiento: fechaVencimiento,
          pagada: false,
        ),
      );
    }

    return cuotas;
  }

  // ===== MÉTODOS PARA PLANTILLAS =====

  /// Obtiene todas las plantillas activas
  Future<List<PlantillaMensaje>> getPlantillas() async {
    try {
      final querySnapshot = await _plantillasCollection
          .where('activo', isEqualTo: true)
          .orderBy('nombre')
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PlantillaMensaje.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error obteniendo plantillas: $e');
      return [];
    }
  }

  /// Obtiene un stream de plantillas
  Stream<List<PlantillaMensaje>> getPlantillasStream() {
    return _plantillasCollection
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return PlantillaMensaje.fromFirestore(data, doc.id);
          }).toList();
        });
  }

  /// Obtiene una plantilla por tipo
  Future<PlantillaMensaje?> getPlantillaByTipo(TipoMensaje tipo) async {
    try {
      print(
        '🔍 WhatsApp Template - Buscando plantilla para tipo: ${tipo.name}',
      );
      final querySnapshot = await _plantillasCollection
          .where(
            'tipo',
            isEqualTo: tipo.name,
          ) // Usar tipo.name en lugar de tipo.toString()
          .where('activa', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        print('✅ WhatsApp Template - Plantilla encontrada: ${data['nombre']}');
        return PlantillaMensaje.fromFirestore(
          data,
          querySnapshot.docs.first.id,
        );
      }
      print(
        '❌ WhatsApp Template - No se encontró plantilla para tipo: ${tipo.name}',
      );
      return null;
    } catch (e) {
      print('💥 Error obteniendo plantilla por tipo ${tipo.name}: $e');
      return null;
    }
  }

  /// Inserta una nueva plantilla
  Future<String?> insertPlantilla(PlantillaMensaje plantilla) async {
    try {
      final docRef = await _plantillasCollection.add(plantilla.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error insertando plantilla: $e');
      return null;
    }
  }

  /// Actualiza una plantilla existente
  Future<bool> updatePlantilla(PlantillaMensaje plantilla) async {
    try {
      print('🔧 Template Update - Actualizando plantilla: ${plantilla.nombre}');
      print('🔧 Template Update - FirestoreId: ${plantilla.firestoreId}');

      if (plantilla.firestoreId == null) {
        print('❌ Template Update - Error: firestoreId es null');
        return false;
      }

      await _plantillasCollection
          .doc(plantilla.firestoreId)
          .update(plantilla.toFirestore());

      print('✅ Template Update - Plantilla actualizada exitosamente');
      return true;
    } catch (e) {
      print('💥 Error actualizando plantilla: $e');
      return false;
    }
  }

  /// Elimina una plantilla (soft delete - marca como inactiva)
  Future<bool> deletePlantilla(String plantillaId) async {
    try {
      await _plantillasCollection.doc(plantillaId).update({'activo': false});
      print('✅ Plantilla marcada como inactiva (soft delete): $plantillaId');
      return true;
    } catch (e) {
      print('Error eliminando plantilla (soft delete): $e');
      return false;
    }
  }

  /// Elimina completamente una plantilla de Firestore (hard delete)
  Future<bool> deletePlantillaCompletamente(String plantillaId) async {
    try {
      await _plantillasCollection.doc(plantillaId).delete();
      print('✅ Plantilla eliminada completamente (hard delete): $plantillaId');
      return true;
    } catch (e) {
      print('Error eliminando plantilla completamente (hard delete): $e');
      return false;
    }
  }

  /// Inicializa las plantillas por defecto si no existen
  Future<void> inicializarPlantillasPorDefecto() async {
    try {
      print('🔧 WhatsApp Template - Verificando plantillas existentes...');
      final plantillasExistentes = await getPlantillas();
      print(
        '📊 WhatsApp Template - Plantillas encontradas: ${plantillasExistentes.length}',
      );

      if (plantillasExistentes.isEmpty) {
        print('🆕 WhatsApp Template - Inicializando plantillas por defecto...');

        final plantillasDefecto = [
          PlantillaMensaje(
            firestoreId: null,
            nombre: 'Recordatorio de Pago',
            tipo: TipoMensaje.recordatorioPago,
            mensaje:
                'Hola {nombre}, te recordamos que tienes una cuota de \${monto} que vence el {fechaVencimiento}. ¡Gracias por tu preferencia!',
            activa: true,
          ),
          PlantillaMensaje(
            firestoreId: null,
            nombre: 'Pago Vencido',
            tipo: TipoMensaje.pagoVencido,
            mensaje:
                'Hola {nombre}, tu cuota de \${monto} venció el {fechaVencimiento}. Por favor, ponte al día con tu pago lo antes posible.',
            activa: true,
          ),
          PlantillaMensaje(
            firestoreId: null,
            nombre: 'Próximo Vencimiento',
            tipo: TipoMensaje.proximoVencimiento,
            mensaje:
                'Hola {nombre}, te recordamos que tu cuota de \${monto} vence el {fechaVencimiento}. ¡No olvides realizar tu pago!',
            activa: true,
          ),
          PlantillaMensaje(
            firestoreId: null,
            nombre: 'Primera Cuota',
            tipo: TipoMensaje.primeraCuota,
            mensaje:
                'Hola {nombre}, tu primera cuota de \${monto} ya está lista. Es por la entrega de materiales. Fecha de vencimiento: {fechaVencimiento}.',
            activa: true,
          ),
        ];

        for (var plantilla in plantillasDefecto) {
          print(
            '💾 WhatsApp Template - Insertando plantilla: ${plantilla.nombre} (tipo: ${plantilla.tipo.name})',
          );
          await insertPlantilla(plantilla);
        }

        print(
          '✅ WhatsApp Template - Plantillas por defecto inicializadas correctamente',
        );
      } else {
        print(
          '✅ WhatsApp Template - Plantillas ya existen, no es necesario inicializar',
        );
        // Mostrar cuales plantillas existen
        for (var plantilla in plantillasExistentes) {
          print(
            '📋 WhatsApp Template - Existente: ${plantilla.nombre} (tipo: ${plantilla.tipo.name})',
          );
        }
      }
    } catch (e) {
      print('💥 Error inicializando plantillas por defecto: $e');
    }
  }
}
