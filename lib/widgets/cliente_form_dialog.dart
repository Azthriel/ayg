import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/cliente.dart';
import '../providers/cliente_provider.dart';

class ClienteFormDialog extends StatefulWidget {
  final Cliente? cliente;

  const ClienteFormDialog({super.key, this.cliente});

  @override
  State<ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<ClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numeroClienteController = TextEditingController();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _montoTotalController = TextEditingController();
  final _numeroCuotasController = TextEditingController();
  final _montoPrimeraCuotaController = TextEditingController();
  final _observacionesController = TextEditingController();

  DateTime _fechaInicio = DateTime.now();
  bool _activo = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.cliente != null) {
      _llenarFormulario(widget.cliente!);
    } else {
      // Valores por defecto para nuevo cliente
      _numeroCuotasController.text = '6';
      _montoPrimeraCuotaController.text = '0.00';
    }
  }

  void _llenarFormulario(Cliente cliente) {
    _numeroClienteController.text = cliente.numeroCliente;
    _nombreController.text = cliente.nombre;
    _emailController.text = cliente.email;
    _telefonoController.text = cliente.telefono;
    _direccionController.text = cliente.direccion;
    _montoTotalController.text = cliente.montoTotal.toString();
    _numeroCuotasController.text = cliente.numeroCuotas.toString();
    _montoPrimeraCuotaController.text = cliente.montoPrimeraCuota.toString();
    _observacionesController.text = cliente.observaciones ?? '';
    _fechaInicio = cliente.fechaInicio;
    _activo = cliente.activo;
  }

  @override
  void dispose() {
    _numeroClienteController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _montoTotalController.dispose();
    _numeroCuotasController.dispose();
    _montoPrimeraCuotaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Número de cliente
                      TextFormField(
                        controller: _numeroClienteController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Cliente *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El número de cliente es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El email es requerido';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Ingrese un email válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Teléfono
                      TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (WhatsApp) *',
                          border: OutlineInputBorder(),
                          hintText: '+54 9 11 1234-5678',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El teléfono es requerido';
                          }
                          final provider = Provider.of<ClienteProvider>(
                            context,
                            listen: false,
                          );
                          if (!provider.validarTelefono(value)) {
                            return 'Ingrese un número de teléfono válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dirección
                      TextFormField(
                        controller: _direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La dirección es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Monto total
                      TextFormField(
                        controller: _montoTotalController,
                        decoration: const InputDecoration(
                          labelText: 'Monto Total *',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El monto total es requerido';
                          }
                          final monto = double.tryParse(value);
                          if (monto == null || monto <= 0) {
                            return 'Ingrese un monto válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Número de cuotas
                      TextFormField(
                        controller: _numeroCuotasController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Cuotas (máx. 13) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El número de cuotas es requerido';
                          }
                          final cuotas = int.tryParse(value);
                          if (cuotas == null || cuotas < 1 || cuotas > 13) {
                            return 'Ingrese entre 1 y 13 cuotas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Monto primera cuota
                      TextFormField(
                        controller: _montoPrimeraCuotaController,
                        decoration: const InputDecoration(
                          labelText:
                              'Monto Primera Cuota (Entrega Materiales) *',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                          hintText: 'Monto de la entrega de materiales',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El monto de la primera cuota es requerido';
                          }
                          final monto = double.tryParse(value);
                          if (monto == null || monto < 0) {
                            return 'Ingrese un monto válido';
                          }
                          final montoTotal = double.tryParse(
                            _montoTotalController.text,
                          );
                          if (montoTotal != null && monto > montoTotal) {
                            return 'No puede ser mayor al monto total';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Fecha de inicio
                      InkWell(
                        onTap: _seleccionarFecha,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Inicio *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Observaciones
                      TextFormField(
                        controller: _observacionesController,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          border: OutlineInputBorder(),
                          hintText: 'Notas adicionales sobre el cliente',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Estado activo
                      SwitchListTile(
                        title: const Text('Cliente Activo'),
                        subtitle: const Text(
                          'Los clientes inactivos no reciben recordatorios',
                        ),
                        value: _activo,
                        onChanged: (value) {
                          setState(() {
                            _activo = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botones
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _guardarCliente,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.cliente == null ? 'Crear' : 'Actualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es'),
    );

    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
      });
    }
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cliente = Cliente(
        id: widget.cliente?.id,
        firestoreId: widget.cliente?.firestoreId, // ← FIX: Preservar firestoreId
        numeroCliente: _numeroClienteController.text.trim(),
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        montoTotal: double.parse(_montoTotalController.text),
        numeroCuotas: int.parse(_numeroCuotasController.text),
        fechaInicio: _fechaInicio,
        montoPrimeraCuota: double.parse(_montoPrimeraCuotaController.text),
        activo: _activo,
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
      );

      final provider = Provider.of<ClienteProvider>(context, listen: false);
      bool exito;

      if (widget.cliente == null) {
        // Verificar que el número de cliente no exista
        final clienteExistente = await provider.buscarClientePorNumero(
          cliente.numeroCliente,
        );
        if (clienteExistente != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ya existe un cliente con ese número'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        exito = await provider.agregarCliente(cliente);
      } else {
        exito = await provider.actualizarCliente(cliente);
      }

      if (mounted) {
        if (exito) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.cliente == null
                    ? 'Cliente creado exitosamente'
                    : 'Cliente actualizado exitosamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.cliente == null
                    ? 'Error al crear el cliente'
                    : 'Error al actualizar el cliente',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
