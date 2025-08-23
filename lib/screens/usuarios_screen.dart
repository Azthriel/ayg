import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/usuario.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Usuario> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usuarios = await authProvider.obtenerUsuarios();
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarUsuarios,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoCrearUsuario,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay usuarios registrados',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargarUsuarios,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = _usuarios[index];
                  return _buildUsuarioCard(usuario);
                },
              ),
            ),
    );
  }

  Widget _buildUsuarioCard(Usuario usuario) {
    final isCurrentUser =
        Provider.of<AuthProvider>(
          context,
          listen: false,
        ).usuarioActual?.firestoreId ==
        usuario.firestoreId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: usuario.activo
              ? (usuario.esAdmin ? Colors.orange : Colors.blue)
              : Colors.grey,
          child: Text(usuario.tipo.icono, style: const TextStyle(fontSize: 20)),
        ),
        title: Row(
          children: [
            Text(
              usuario.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tú',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuario: ${usuario.usuario}'),
            Text('Email: ${usuario.email}'),
            Text('Tipo: ${usuario.tipo.descripcion}'),
            Text('Estado: ${usuario.activo ? "Activo" : "Inactivo"}'),
            if (usuario.ultimoAcceso != null)
              Text(
                'Último acceso: ${_formatearFecha(usuario.ultimoAcceso!)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón activar/desactivar
            if (!isCurrentUser)
              IconButton(
                icon: Icon(
                  usuario.activo ? Icons.person_off : Icons.person,
                  color: usuario.activo ? Colors.red : Colors.green,
                ),
                onPressed: () => _toggleUsuarioActivo(usuario),
                tooltip: usuario.activo ? 'Desactivar' : 'Activar',
              ),
            // Botón cambiar contraseña
            IconButton(
              icon: const Icon(Icons.lock_reset, color: Colors.orange),
              onPressed: () =>
                  _mostrarDialogoCambiarPassword(usuario, isCurrentUser),
              tooltip: 'Cambiar contraseña',
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleUsuarioActivo(Usuario usuario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${usuario.activo ? 'Desactivar' : 'Activar'} Usuario'),
        content: Text(
          '¿Estás seguro de que quieres ${usuario.activo ? 'desactivar' : 'activar'} '
          'al usuario "${usuario.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: usuario.activo ? Colors.red : Colors.green,
            ),
            child: Text(usuario.activo ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.toggleUsuarioActivo(
        usuario.firestoreId!,
        !usuario.activo,
      );

      if (success) {
        _cargarUsuarios(); // Recargar la lista
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Usuario ${!usuario.activo ? 'activado' : 'desactivado'} exitosamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Error al modificar usuario'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _mostrarDialogoCambiarPassword(Usuario usuario, bool isCurrentUser) {
    final passwordActualController = TextEditingController();
    final passwordNuevoController = TextEditingController();
    final passwordConfirmarController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cambiar Contraseña${isCurrentUser ? '' : ' - ${usuario.nombre}'}',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrentUser) ...[
                TextFormField(
                  controller: passwordActualController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: passwordNuevoController,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo requerido';
                  if (value!.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordConfirmarController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo requerido';
                  if (value != passwordNuevoController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                bool success = false;

                if (isCurrentUser) {
                  success = await authProvider.cambiarPassword(
                    passwordActualController.text,
                    passwordNuevoController.text,
                  );
                } else {
                  // Para otros usuarios, un admin puede cambiar la contraseña directamente
                  // Implementar lógica específica aquí si es necesario
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Contraseña cambiada exitosamente'
                            : authProvider.error ?? 'Error desconocido',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearUsuario() {
    final usuarioController = TextEditingController();
    final passwordController = TextEditingController();
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    TipoUsuario tipoSeleccionado = TipoUsuario.usuario;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crear Nuevo Usuario'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usuarioController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Campo requerido';
                      if (value!.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Campo requerido';
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value!)) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TipoUsuario>(
                    value: tipoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de usuario',
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                    items: TipoUsuario.values.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Row(
                          children: [
                            Text(tipo.icono),
                            const SizedBox(width: 8),
                            Text(tipo.descripcion),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        tipoSeleccionado = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final success = await authProvider.crearUsuario(
                    usuario: usuarioController.text.trim(),
                    password: passwordController.text,
                    nombre: nombreController.text.trim(),
                    email: emailController.text.trim(),
                    tipo: tipoSeleccionado,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Usuario creado exitosamente'
                              : authProvider.error ?? 'Error desconocido',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );

                    if (success) {
                      _cargarUsuarios(); // Recargar la lista
                    }
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
