import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cliente_provider.dart';
import '../models/cliente.dart';
import '../widgets/cliente_form_dialog.dart';
import '../widgets/cliente_list_item.dart';
import '../utils/currency_formatter.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmarReactivarCliente(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivar cliente'),
        content: const Text('¿Deseas reactivar este cliente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<ClienteProvider>(
                context,
                listen: false,
              );
              final actualizado = await provider.actualizarCliente(
                cliente.copyWith(activo: true),
              );
              if (actualizado && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente reactivado')),
                );
              }
            },
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminarDefinitivo(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar definitivamente'),
        content: const Text(
          'Esta acción eliminará el cliente y sus cuotas de forma permanente. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<ClienteProvider>(
                context,
                listen: false,
              );
              final eliminado = await provider.eliminarClienteCompletamente(
                cliente.firestoreId!,
              );
              if (eliminado && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cliente eliminado definitivamente'),
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminarCliente(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar cliente'),
        content: Text(
          '¿Está seguro que desea desactivar al cliente ${cliente.nombre}?\n\n'
          'El cliente no será eliminado, solo quedará inactivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<ClienteProvider>(
                context,
                listen: false,
              );
              final actualizado = await provider.actualizarCliente(
                cliente.copyWith(activo: false),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      actualizado
                          ? 'Cliente desactivado exitosamente'
                          : 'Error al desactivar el cliente',
                    ),
                    backgroundColor: actualizado ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'Desactivar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClienteProvider>(
      builder: (context, provider, child) {
        final clientesFiltrados = provider.filtrarClientes(_searchQuery);

        return Scaffold(
          body: Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar cliente...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Lista de clientes
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : clientesFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay clientes registrados'
                                  : 'No se encontraron clientes',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _mostrarFormularioCliente(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Agregar primer cliente'),
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.cargarClientes(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final cliente = clientesFiltrados[index];
                            return ClienteListItem(
                              cliente: cliente,
                              onTap: () =>
                                  _mostrarDetalleCliente(context, cliente),
                              onEdit: () {
                                if (cliente.activo) {
                                  _mostrarFormularioCliente(
                                    context,
                                    cliente: cliente,
                                  );
                                } else {
                                  _confirmarReactivarCliente(context, cliente);
                                }
                              },
                              onDelete: () {
                                if (cliente.activo) {
                                  _confirmarEliminarCliente(context, cliente);
                                } else {
                                  _confirmarEliminarDefinitivo(
                                    context,
                                    cliente,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _mostrarFormularioCliente(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _mostrarFormularioCliente(BuildContext context, {Cliente? cliente}) {
    showDialog(
      context: context,
      builder: (context) => ClienteFormDialog(cliente: cliente),
    ).then((_) {
      // Recargar datos después de cerrar el diálogo
      if (context.mounted) {
        Provider.of<ClienteProvider>(context, listen: false).cargarClientes();
      }
    });
  }

  void _mostrarDetalleCliente(BuildContext context, Cliente cliente) {
    final provider = Provider.of<ClienteProvider>(context, listen: false);
    provider.seleccionarCliente(cliente);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalle del Cliente',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),

              // Información del cliente
              _buildInfoRow('Número de Cliente:', cliente.numeroCliente),
              _buildInfoRow('Nombre:', cliente.nombre),
              _buildInfoRow('Email:', cliente.email),
              _buildInfoRow('Teléfono:', cliente.telefono),
              _buildInfoRow('Dirección:', cliente.direccion),
              _buildInfoRow(
                'Monto Total:',
                '\$${cliente.montoTotal.toStringAsFixed(2)}',
              ),
              _buildInfoRow(
                'Número de Cuotas:',
                cliente.numeroCuotas.toString(),
              ),
              _buildInfoRow('Estado:', cliente.activo ? 'Activo' : 'Inactivo'),

              // Observaciones del cliente
              if (cliente.observaciones != null &&
                  cliente.observaciones!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note_alt,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Observaciones:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cliente.observaciones!,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Lista de cuotas
              Text(
                'Plan de Pagos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Expanded(
                child: Consumer<ClienteProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Filtrar cuotas del cliente actual
                    final cuotasCliente = provider.cuotas
                        .where((c) => c.clienteId == cliente.firestoreId)
                        .toList();
                    if (cuotasCliente.isEmpty) {
                      return const Center(
                        child: Text('No hay cuotas asociadas a este cliente.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: cuotasCliente.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cuota = cuotasCliente[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cuota.pagada
                                  ? Colors.green
                                  : cuota.estaVencida
                                  ? Colors.red
                                  : Colors.orange,
                              child: Text(
                                cuota.numeroCuota.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              'Cuota ${cuota.numeroCuota}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vence: ${cuota.fechaVencimiento.day}/${cuota.fechaVencimiento.month}/${cuota.fechaVencimiento.year}',
                                ),
                                if (cuota.observaciones != null &&
                                    cuota.observaciones!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Obs: ${cuota.observaciones!}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.formatCurrency(cuota.monto),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  cuota.pagada ? 'Pagada' : 'Pendiente',
                                  style: TextStyle(
                                    color: cuota.pagada
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
