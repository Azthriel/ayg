import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plantilla_mensaje.dart';
import '../providers/cliente_provider.dart';

class PlantillaFormDialog extends StatefulWidget {
  final PlantillaMensaje? plantilla;

  const PlantillaFormDialog({super.key, this.plantilla});

  @override
  State<PlantillaFormDialog> createState() => _PlantillaFormDialogState();
}

class _PlantillaFormDialogState extends State<PlantillaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _mensajeController = TextEditingController();

  TipoMensaje _tipoSeleccionado = TipoMensaje.personalizada; // Por defecto personalizada
  bool _activa = true;
  bool _isLoading = false;
  IconData _iconoSeleccionado = Icons.message; // Icono por defecto

  // Lista de iconos disponibles para seleccionar
  final List<IconData> _iconosDisponibles = [
    Icons.message,
    Icons.notifications,
    Icons.payment,
    Icons.schedule,
    Icons.warning,
    Icons.info,
    Icons.check_circle,
    Icons.star,
    Icons.favorite,
    Icons.phone,
    Icons.mail,
    Icons.calendar_today,
    Icons.home,
    Icons.work,
    Icons.person,
    Icons.group,
    Icons.money,
    Icons.credit_card,
    Icons.receipt,
    Icons.alarm,
  ];

  final List<String> _variablesDisponibles = [
    '{NOMBRE}',
    '{NUMERO_CLIENTE}',
    '{NUMERO_CUOTA}',
    '{MONTO}',
    '{FECHA_VENCIMIENTO}',
    '{DIRECCION}',
    '{EMAIL}',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.plantilla != null) {
      _llenarFormulario(widget.plantilla!);
    }
  }

  void _llenarFormulario(PlantillaMensaje plantilla) {
    _nombreController.text = plantilla.nombre;
    _mensajeController.text = plantilla.mensaje;
    _tipoSeleccionado = plantilla.tipo;
    _activa = plantilla.activa;
    // Cargar icono si existe
    if (plantilla.iconCodePoint != null) {
      _iconoSeleccionado = IconData(plantilla.iconCodePoint!, fontFamily: 'MaterialIcons');
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _mostrarSelectorIconos() async {
    final icono = await showDialog<IconData>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Icono'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _iconosDisponibles.length,
              itemBuilder: (context, index) {
                final iconData = _iconosDisponibles[index];
                return InkWell(
                  onTap: () => Navigator.of(context).pop(iconData),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _iconoSeleccionado == iconData 
                            ? Colors.purple 
                            : Colors.grey.shade300,
                        width: _iconoSeleccionado == iconData ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      iconData,
                      color: _iconoSeleccionado == iconData 
                          ? Colors.purple 
                          : Colors.grey.shade600,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (icono != null) {
      setState(() {
        _iconoSeleccionado = icono;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.plantilla == null
                      ? 'Nueva Plantilla'
                      : 'Editar Plantilla',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la Plantilla *',
                          border: OutlineInputBorder(),
                          hintText: 'Ej: Recordatorio Estándar',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Selector de Icono (solo para plantillas personalizadas)
                      if (_tipoSeleccionado == TipoMensaje.personalizada) ...[
                        Text(
                          'Icono *',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _mostrarSelectorIconos,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _iconoSeleccionado,
                                  color: Colors.purple,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text('Seleccionar icono'),
                                const Spacer(),
                                const Icon(Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Tipo de mensaje
                      DropdownButtonFormField<TipoMensaje>(
                        value: _tipoSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Mensaje *',
                          border: OutlineInputBorder(),
                        ),
                        items: TipoMensaje.values.map((tipo) {
                          return DropdownMenuItem(
                            value: tipo,
                            child: Row(
                              children: [
                                Icon(
                                  _getTipoIcon(tipo),
                                  color: _getTipoColor(tipo),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(tipo.descripcion),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _tipoSeleccionado = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mensaje
                      Text(
                        'Mensaje *',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _mensajeController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Escribe tu mensaje aquí...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El mensaje es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Variables disponibles
                      Text(
                        'Variables Disponibles',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Haz clic en una variable para agregarla al mensaje:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _variablesDisponibles.map((variable) {
                          return ActionChip(
                            label: Text(variable),
                            onPressed: () => _insertarVariable(variable),
                            backgroundColor: Colors.blue[100],
                            avatar: const Icon(Icons.add, size: 16),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Vista previa
                      Text(
                        'Vista Previa',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _generarVistaPrevia(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Estado activo
                      SwitchListTile(
                        title: const Text('Plantilla Activa'),
                        subtitle: const Text(
                          'Las plantillas inactivas no están disponibles para uso',
                        ),
                        value: _activa,
                        onChanged: (value) {
                          setState(() {
                            _activa = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Ayuda
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.blue[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ayuda',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Las variables se reemplazan automáticamente con los datos del cliente y cuota\n'
                              '• Puedes usar saltos de línea normalmente\n'
                              '• El mensaje se enviará a través de WhatsApp\n'
                              '• Mantén los mensajes claros y profesionales',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
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
                  onPressed: _isLoading ? null : _guardarPlantilla,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.plantilla == null ? 'Crear' : 'Actualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _insertarVariable(String variable) {
    final cursorPos = _mensajeController.selection.baseOffset;
    final text = _mensajeController.text;

    if (cursorPos >= 0) {
      final newText =
          text.substring(0, cursorPos) + variable + text.substring(cursorPos);
      _mensajeController.text = newText;
      _mensajeController.selection = TextSelection.fromPosition(
        TextPosition(offset: cursorPos + variable.length),
      );
    } else {
      _mensajeController.text += variable;
    }

    setState(() {}); // Para actualizar la vista previa
  }

  String _generarVistaPrevia() {
    if (_mensajeController.text.isEmpty) {
      return 'Escribe un mensaje para ver la vista previa...';
    }

    return _mensajeController.text
        .replaceAll('{NOMBRE}', 'Juan Pérez')
        .replaceAll('{NUMERO_CLIENTE}', 'C001')
        .replaceAll('{NUMERO_CUOTA}', '2')
        .replaceAll('{MONTO}', '1,500.00')
        .replaceAll('{FECHA_VENCIMIENTO}', '15/02/2025')
        .replaceAll('{DIRECCION}', 'Av. Ejemplo 123, Ciudad')
        .replaceAll('{EMAIL}', 'juan.perez@email.com');
  }

  Color _getTipoColor(TipoMensaje tipo) {
    switch (tipo) {
      case TipoMensaje.recordatorioPago:
        return Colors.blue;
      case TipoMensaje.pagoVencido:
        return Colors.red;
      case TipoMensaje.proximoVencimiento:
        return Colors.orange;
      case TipoMensaje.primeraCuota:
        return Colors.green;
      case TipoMensaje.personalizada:
        return Colors.purple;
    }
  }

  IconData _getTipoIcon(TipoMensaje tipo) {
    switch (tipo) {
      case TipoMensaje.recordatorioPago:
        return Icons.payment;
      case TipoMensaje.pagoVencido:
        return Icons.warning;
      case TipoMensaje.proximoVencimiento:
        return Icons.schedule;
      case TipoMensaje.primeraCuota:
        return Icons.inventory;
      case TipoMensaje.personalizada:
        return _iconoSeleccionado; // Usar el icono seleccionado por el usuario
    }
  }

  Future<void> _guardarPlantilla() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final plantilla = PlantillaMensaje(
        id: widget.plantilla?.id,
        firestoreId: widget.plantilla?.firestoreId, // ✅ Preservar firestoreId en actualizaciones
        nombre: _nombreController.text.trim(),
        mensaje: _mensajeController.text.trim(),
        tipo: _tipoSeleccionado,
        activa: _activa,
        iconCodePoint: _tipoSeleccionado == TipoMensaje.personalizada 
            ? _iconoSeleccionado.codePoint 
            : null, // Solo guardar icono para plantillas personalizadas
      );

      final provider = Provider.of<ClienteProvider>(context, listen: false);
      bool exito;

      if (widget.plantilla == null) {
        exito = await provider.agregarPlantilla(plantilla);
      } else {
        exito = await provider.actualizarPlantilla(plantilla);
      }

      if (mounted) {
        if (exito) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.plantilla == null
                    ? 'Plantilla creada exitosamente'
                    : 'Plantilla actualizada exitosamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.plantilla == null
                    ? 'Error al crear la plantilla'
                    : 'Error al actualizar la plantilla',
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
