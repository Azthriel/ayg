import 'package:flutter/foundation.dart';
import '../models/cliente.dart';
import '../models/cuota.dart';
import '../models/plantilla_mensaje.dart';
import '../services/firestore_service.dart';
import '../services/whatsapp_service.dart';

class ClienteProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final WhatsAppService _whatsappService = WhatsAppService();

  List<Cliente> _clientes = [];
  List<Cuota> _cuotas = [];
  List<PlantillaMensaje> _plantillas = [];
  Cliente? _clienteSeleccionado;
  bool _isLoading = false;

  // Cache para optimizar lecturas
  DateTime? _lastClientesLoad;
  DateTime? _lastCuotasLoad;
  DateTime? _lastPlantillasLoad;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  // Getters
  List<Cliente> get clientes => _clientes;
  List<Cuota> get cuotas => _cuotas;
  List<PlantillaMensaje> get plantillas => _plantillas;
  Cliente? get clienteSeleccionado => _clienteSeleccionado;
  bool get isLoading => _isLoading;

  // Estadísticas
  int get totalClientes => _clientes.length;
  int get clientesActivos => _clientes.where((c) => c.activo).length;
  List<Cuota> get cuotasVencidas =>
      _cuotas.where((c) => c.estaVencida && !c.pagada && c.activo).toList();
  List<Cuota> get cuotasProximas => _cuotas
      .where((c) => c.venceProximamente && !c.pagada && c.activo)
      .toList();

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Métodos auxiliares para cache
  bool _shouldReloadClientes() {
    return _lastClientesLoad == null ||
        DateTime.now().difference(_lastClientesLoad!) > _cacheTimeout;
  }

  bool _shouldReloadCuotas() {
    return _lastCuotasLoad == null ||
        DateTime.now().difference(_lastCuotasLoad!) > _cacheTimeout;
  }

  bool _shouldReloadPlantillas() {
    return _lastPlantillasLoad == null ||
        DateTime.now().difference(_lastPlantillasLoad!) > _cacheTimeout;
  }

  /// Fuerza la recarga de datos invalidando el cache
  void invalidarCache() {
    _lastClientesLoad = null;
    _lastCuotasLoad = null;
    _lastPlantillasLoad = null;
    print('Cache invalidado - próximas cargas serán desde Firestore');
  }

  // ===== MÉTODOS PARA CLIENTES =====

  Future<void> cargarClientes() async {
    if (!_shouldReloadClientes() && _clientes.isNotEmpty) {
      print('Usando cache de clientes (${_clientes.length} clientes)');
      return;
    }

    _setLoading(true);
    try {
      print('Cargando clientes desde Firestore...');
      _clientes = await _firestoreService.getClientes();
      _lastClientesLoad = DateTime.now();
      print('Clientes cargados: ${_clientes.length}');
      notifyListeners();
    } catch (e) {
      print('Error al cargar clientes: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> agregarCliente(Cliente cliente) async {
    _setLoading(true);
    try {
      final firestoreId = await _firestoreService.insertCliente(cliente);
      if (firestoreId != null) {
        final clienteConId = cliente.copyWith(firestoreId: firestoreId);
        _clientes.add(clienteConId);
        // Crear cuotas automáticamente
        final List<Cuota> cuotasGeneradas = [];
        final DateTime fechaInicio = cliente.fechaInicio;
        final int numeroCuotas = cliente.numeroCuotas;
        final double montoTotal = cliente.montoTotal;
        final double montoPrimeraCuota = cliente.montoPrimeraCuota;
        final double montoPorCuota = numeroCuotas > 0 ? (montoTotal - montoPrimeraCuota) / numeroCuotas : 0.0;

        // 1. Crear cuota de entrega de materiales
        final cuotaEntrega = Cuota(
          clienteId: firestoreId,
          numeroCuota: 1,
          fechaVencimiento: fechaInicio,
          monto: montoPrimeraCuota,
          pagada: false,
          activo: true,
          observaciones: '🛠️ Entrega de materiales',
        );
        final cuotaEntregaId = await _firestoreService.insertCuota(cuotaEntrega);
        if (cuotaEntregaId != null) {
          cuotasGeneradas.add(cuotaEntrega.copyWith(firestoreId: cuotaEntregaId));
        }

        // 2. Crear cuotas normales
        for (int i = 0; i < numeroCuotas; i++) {
          DateTime fechaVencimiento = fechaInicio.add(Duration(days: 30 * (i + 1)));
          final cuota = Cuota(
            clienteId: firestoreId,
            numeroCuota: i + 2,
            fechaVencimiento: fechaVencimiento,
            monto: montoPorCuota,
            pagada: false,
            activo: true,
          );
          final cuotaId = await _firestoreService.insertCuota(cuota);
          if (cuotaId != null) {
            cuotasGeneradas.add(cuota.copyWith(firestoreId: cuotaId));
          }
        }
        _cuotas.addAll(cuotasGeneradas);
        notifyListeners();
        print('Cliente ${cliente.nombre} y sus cuotas agregados localmente');
        return true;
      }
    } catch (e) {
      print('Error al agregar cliente y cuotas: $e');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> actualizarCliente(Cliente cliente) async {
    print(
      '🔧 Provider - Iniciando actualización de cliente: ${cliente.nombre}',
    );
    print('🔧 Provider - FirestoreId del cliente: ${cliente.firestoreId}');

    _setLoading(true);
    try {
      final result = await _firestoreService.updateCliente(cliente);
      if (result) {
        final index = _clientes.indexWhere(
          (c) => c.firestoreId == cliente.firestoreId,
        );
        if (index != -1) {
          _clientes[index] = cliente;
          notifyListeners();
          print(
            '✅ Provider - Cliente ${cliente.nombre} actualizado localmente',
          );
        } else {
          print('⚠️ Provider - No se encontró el cliente en la lista local');
        }
        return true;
      } else {
        print('❌ Provider - Fallo la actualización en Firestore');
      }
    } catch (e) {
      print('💥 Provider - Error al actualizar cliente: $e');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  void seleccionarCliente(Cliente? cliente) {
    _clienteSeleccionado = cliente;
    print('Cliente seleccionado: ${cliente?.nombre ?? "ninguno"}');
    notifyListeners();
  }

  /// Busca clientes por nombre o número
  Future<void> buscarClientes(String query) async {
    if (query.isEmpty) {
      await cargarClientes();
      return;
    }

    _setLoading(true);
    try {
      final clientesOriginales = await _firestoreService.getClientes();
      _clientes = clientesOriginales
          .where(
            (cliente) =>
                cliente.nombre.toLowerCase().contains(query.toLowerCase()) ||
                cliente.numeroCliente.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                cliente.email.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      print('Búsqueda "$query" - Resultados: ${_clientes.length}');
      notifyListeners();
    } catch (e) {
      print('Error en búsqueda de clientes: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Busca un cliente por número específico
  Future<Cliente?> buscarClientePorNumero(String numeroCliente) async {
    try {
      final clientes = await _firestoreService.getClientes();
      return clientes
          .where((cliente) => cliente.numeroCliente == numeroCliente)
          .firstOrNull;
    } catch (e) {
      print('Error buscando cliente por número: $e');
      return null;
    }
  }

  /// Elimina un cliente (soft delete)
  Future<bool> eliminarCliente(String clienteId) async {
    _setLoading(true);
    try {
      final result = await _firestoreService.deleteCliente(clienteId);
      if (result) {
        _clientes.removeWhere((c) => c.firestoreId == clienteId);
        notifyListeners();
        print('Cliente eliminado localmente');
        return true;
      }
    } catch (e) {
      print('Error al eliminar cliente: $e');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ===== MÉTODOS PARA CUOTAS =====

  /// Carga todas las cuotas para la pantalla de cuotas (SIEMPRE todas, sin filtros)
  Future<void> cargarTodasLasCuotas() async {
    _setLoading(true);
    try {
      print('🔄 CuotasScreen - Cargando TODAS las cuotas desde Firestore...');
      _cuotas = await _firestoreService.getAllCuotas();
      print('✅ CuotasScreen - Total cuotas cargadas: ${_cuotas.length}');

      // Debug: mostrar distribución de cuotas
      final activas = _cuotas.where((c) => c.activo).length;
      final pagadas = _cuotas.where((c) => c.pagada).length;
      final vencidas = _cuotas.where((c) => c.estaVencida && !c.pagada).length;

      print(
        '📊 CuotasScreen - Distribución: $activas activas, $pagadas pagadas, $vencidas vencidas',
      );

      _lastCuotasLoad = DateTime.now();
      notifyListeners();
    } catch (e) {
      print('💥 Error cargando todas las cuotas: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carga cuotas específicas de un cliente
  Future<void> cargarCuotasCliente(String clienteId) async {
    // Solo recargar si es necesario
    if (!_shouldReloadCuotas() && _cuotas.isNotEmpty) {
      print('Usando cache de cuotas del cliente');
      return;
    }

    _setLoading(true);
    try {
      print('Cargando cuotas para cliente $clienteId...');
      _cuotas = await _firestoreService.getCuotasByCliente(clienteId);
      _lastCuotasLoad = DateTime.now();
      print('Cuotas del cliente cargadas: ${_cuotas.length}');
      notifyListeners();
    } catch (e) {
      print('Error al cargar cuotas del cliente: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> marcarCuotaComoPagada(
    Cuota cuota, {
    String? observacionesAdicionales,
  }) async {
    _setLoading(true);
    try {
      if (cuota.firestoreId == null) return false;

      final result = await _firestoreService.marcarCuotaComoPagada(
        cuota.firestoreId!,
        DateTime.now(),
        observacionesAdicionales,
      );

      if (result) {
        // Recargar cuotas
        await cargarTodasLasCuotas();
        return true;
      }
    } catch (e) {
      print('Error al marcar cuota como pagada: $e');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  /// Actualiza una cuota específica
  Future<bool> actualizarCuota(Cuota cuota) async {
    _setLoading(true);
    try {
      final result = await _firestoreService.updateCuota(cuota);
      if (result) {
        // Actualizar localmente
        final index = _cuotas.indexWhere(
          (c) => c.firestoreId == cuota.firestoreId,
        );
        if (index != -1) {
          _cuotas[index] = cuota;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      print('Error al actualizar cuota: $e');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  /// Actualiza observaciones de un cliente
  Future<bool> actualizarObservacionesCliente(
    String clienteId,
    String observaciones,
  ) async {
    _setLoading(true);
    try {
      final success = await _firestoreService.updateClienteObservaciones(
        clienteId,
        observaciones,
      );

      if (success) {
        // Actualizar cliente local
        final index = _clientes.indexWhere((c) => c.firestoreId == clienteId);
        if (index != -1) {
          _clientes[index] = _clientes[index].copyWith(
            observaciones: observaciones,
          );
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      print('Error actualizando observaciones del cliente: $e');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ===== MÉTODOS PARA PLANTILLAS =====

  Future<void> cargarPlantillas() async {
    if (!_shouldReloadPlantillas() && _plantillas.isNotEmpty) {
      print('Usando cache de plantillas (${_plantillas.length} plantillas)');
      return;
    }

    _setLoading(true);
    try {
      await _firestoreService.inicializarPlantillasPorDefecto();
      _plantillas = await _firestoreService.getPlantillas();
      _lastPlantillasLoad = DateTime.now();
      print('Plantillas cargadas: ${_plantillas.length}');
      notifyListeners();
    } catch (e) {
      print('Error al cargar plantillas: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> agregarPlantilla(PlantillaMensaje plantilla) async {
    _setLoading(true);
    try {
      final firestoreId = await _firestoreService.insertPlantilla(plantilla);
      if (firestoreId != null) {
        final plantillaConId = plantilla.copyWith(firestoreId: firestoreId);
        _plantillas.add(plantillaConId);
        notifyListeners();
        print('Plantilla ${plantilla.nombre} agregada localmente');
        return true;
      }
    } catch (e) {
      print('Error al agregar plantilla: $e');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> actualizarPlantilla(PlantillaMensaje plantilla) async {
    print(
      '🔧 Provider - Iniciando actualización de plantilla: ${plantilla.nombre}',
    );
    print(
      '🔧 Provider - FirestoreId de la plantilla: ${plantilla.firestoreId}',
    );

    _setLoading(true);
    try {
      final result = await _firestoreService.updatePlantilla(plantilla);
      if (result) {
        final index = _plantillas.indexWhere(
          (p) => p.firestoreId == plantilla.firestoreId,
        );
        if (index != -1) {
          _plantillas[index] = plantilla;
          notifyListeners();
          print(
            '✅ Provider - Plantilla ${plantilla.nombre} actualizada localmente',
          );
        } else {
          print('⚠️ Provider - No se encontró la plantilla en la lista local');
        }
        return true;
      } else {
        print('❌ Provider - Fallo la actualización en Firestore');
      }
    } catch (e) {
      print('💥 Provider - Error al actualizar plantilla: $e');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  /// Elimina una plantilla completamente de Firestore
  Future<bool> eliminarPlantilla(String firestoreId) async {
    _setLoading(true);
    try {
      // Usar hard delete para eliminar completamente
      final result = await _firestoreService.deletePlantillaCompletamente(
        firestoreId,
      );
      if (result) {
        _plantillas.removeWhere((p) => p.firestoreId == firestoreId);
        notifyListeners();
        print('✅ Plantilla eliminada completamente de Firestore y UI');
        return true;
      }
    } catch (e) {
      print('❌ Error al eliminar plantilla: $e');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ===== MÉTODOS PARA WHATSAPP =====

  Future<bool> enviarMensajeWhatsApp(String telefono, String mensaje) async {
    return await _whatsappService.enviarMensaje(telefono, mensaje);
  }

  Future<bool> enviarRecordatorioPago(Cliente cliente, Cuota cuota) async {
    return await _whatsappService.enviarRecordatorioPago(cliente, cuota);
  }

  Future<bool> enviarNotificacionVencida(Cliente cliente, Cuota cuota) async {
    return await _whatsappService.enviarNotificacionVencida(cliente, cuota);
  }

  Future<bool> enviarNotificacionProximoVencimiento(
    Cliente cliente,
    Cuota cuota,
  ) async {
    return await _whatsappService.enviarNotificacionProximoVencimiento(
      cliente,
      cuota,
    );
  }

  Future<bool> enviarNotificacionPrimeraCuota(
    Cliente cliente,
    Cuota cuota,
  ) async {
    return await _whatsappService.enviarNotificacionPrimeraCuota(
      cliente,
      cuota,
    );
  }

  /// Envía un mensaje usando una plantilla específica
  Future<bool> enviarMensajeConPlantilla(
    Cliente cliente,
    Cuota cuota,
    PlantillaMensaje plantilla,
  ) async {
    try {
      // Procesar las variables en el mensaje de la plantilla
      final mensaje = _procesarVariablesEnMensaje(
        plantilla.mensaje,
        cliente,
        cuota,
      );

      // Enviar el mensaje
      return await _whatsappService.enviarMensaje(cliente.telefono, mensaje);
    } catch (e) {
      print('Error enviando mensaje con plantilla: $e');
      return false;
    }
  }

  /// Procesa las variables en un mensaje de plantilla
  String _procesarVariablesEnMensaje(
    String mensaje,
    Cliente cliente,
    Cuota cuota,
  ) {
    return mensaje
        .replaceAll('{NOMBRE}', cliente.nombre)
        .replaceAll('{NUMERO_CLIENTE}', cliente.numeroCliente)
        .replaceAll('{NUMERO_CUOTA}', cuota.numeroCuota.toString())
        .replaceAll('{MONTO}', '\$${cuota.monto.toStringAsFixed(2)}')
        .replaceAll(
          '{FECHA_VENCIMIENTO}',
          '${cuota.fechaVencimiento.day}/${cuota.fechaVencimiento.month}/${cuota.fechaVencimiento.year}',
        )
        .replaceAll('{DIRECCION}', cliente.direccion)
        .replaceAll('{EMAIL}', cliente.email)
        // También soportar variables en minúsculas
        .replaceAll('{nombre}', cliente.nombre)
        .replaceAll('{numeroCliente}', cliente.numeroCliente)
        .replaceAll('{numeroCuota}', cuota.numeroCuota.toString())
        .replaceAll('{monto}', '\$${cuota.monto.toStringAsFixed(2)}')
        .replaceAll(
          '{fechaVencimiento}',
          '${cuota.fechaVencimiento.day}/${cuota.fechaVencimiento.month}/${cuota.fechaVencimiento.year}',
        )
        .replaceAll('{direccion}', cliente.direccion)
        .replaceAll('{email}', cliente.email);
  }

  Future<List<String>> enviarRecordatoriosMasivos() async {
    return await _whatsappService.enviarRecordatoriosMasivos();
  }

  /// Genera lista de mensajes para envío manual (más práctico)
  Future<List<Map<String, String>>> generarMensajesMasivos() async {
    return await _whatsappService.generarMensajesMasivos();
  }

  // ===== MÉTODOS AUXILIARES =====

  bool validarTelefono(String telefono) {
    return _whatsappService.validarTelefono(telefono);
  }

  String formatearTelefono(String telefono) {
    return _whatsappService.formatearTelefono(telefono);
  }

  List<Cliente> filtrarClientes(String query) {
    if (query.isEmpty) return _clientes;

    return _clientes
        .where(
          (cliente) =>
              cliente.nombre.toLowerCase().contains(query.toLowerCase()) ||
              cliente.numeroCliente.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              cliente.email.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  List<Cuota> filtrarCuotas({
    bool? vencidas,
    bool? pagadas,
    String? clienteId,
  }) {
    var cuotasFiltradas = List<Cuota>.from(_cuotas);

    if (vencidas != null) {
      cuotasFiltradas = cuotasFiltradas
          .where((c) => c.estaVencida == vencidas)
          .toList();
    }

    if (pagadas != null) {
      cuotasFiltradas = cuotasFiltradas
          .where((c) => c.pagada == pagadas)
          .toList();
    }

    if (clienteId != null) {
      cuotasFiltradas = cuotasFiltradas
          .where((c) => c.clienteId == clienteId)
          .toList();
    }

    return cuotasFiltradas;
  }

  /// Limpia todos los datos (útil para logout o reset)
  void limpiarDatos() {
    _setLoading(true);
    try {
      _clientes = [];
      _cuotas = [];
      _plantillas = [];
      _clienteSeleccionado = null;
      _lastClientesLoad = null;
      _lastCuotasLoad = null;
      _lastPlantillasLoad = null;
      notifyListeners();
      print('Datos limpiados');
    } finally {
      _setLoading(false);
    }
  }
}
