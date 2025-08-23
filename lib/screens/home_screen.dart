import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cliente_provider.dart';
import '../providers/auth_provider.dart';
import '../models/usuario.dart';
import '../widgets/dashboard_card.dart';
import 'clientes_screen.dart';
import 'cuotas_screen.dart';
import 'plantillas_screen.dart';
import 'usuarios_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  List<Widget> get _screens {
    final authProvider = Provider.of<AuthProvider>(context);
    List<Widget> screens = [
      const SizedBox.shrink(), // Placeholder para dashboard, se maneja por separado
      const ClientesScreen(),
      const CuotasScreen(),
      const PlantillasScreen(),
    ];
    
    // Agregar pantalla de usuarios solo para admins
    if (authProvider.isAdmin) {
      screens.add(const UsuariosScreen());
    }
    
    return screens;
  }

  List<BottomNavigationBarItem> get _items {
    final authProvider = Provider.of<AuthProvider>(context);
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
      const BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Cuotas'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.message),
        label: 'Plantillas',
      ),
    ];
    
    // Agregar item de usuarios solo para admins
    if (authProvider.isAdmin) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Usuarios',
        ),
      );
    }
    
    return items;
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ClienteProvider>(context, listen: false);
      provider.cargarClientes();
      provider.cargarPlantillas();
      provider.cargarTodasLasCuotas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'AYG - Sistema de Gestión',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            elevation: 2,
            actions: [
              // Información del usuario actual
              PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: authProvider.isAdmin ? Colors.orange : Colors.blue,
                  radius: 16,
                  child: Text(
                    authProvider.usuarioActual?.tipo.icono ?? '👤',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.usuarioActual?.nombre ?? 'Usuario',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '@${authProvider.usuarioActual?.usuario ?? ''}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        Text(
                          authProvider.usuarioActual?.tipo.descripcion ?? '',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'cambiar_password',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset, size: 20),
                        SizedBox(width: 12),
                        Text('Cambiar contraseña'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'cambiar_password':
                      _mostrarDialogoCambiarPassword(context);
                      break;
                    case 'logout':
                      _logout(context, authProvider);
                      break;
                  }
                },
              ),
            ],
          ),
          body: _selectedIndex == 0
              ? DashboardTab(
                  onNavigateToTab: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                )
              : _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: _items,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
          ),
        );
      },
    );
  }

  void _mostrarDialogoCambiarPassword(BuildContext context) {
    final passwordActualController = TextEditingController();
    final passwordNuevoController = TextEditingController();
    final passwordConfirmarController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordActualController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
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
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider.cambiarPassword(
                  passwordActualController.text,
                  passwordNuevoController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? 'Contraseña cambiada exitosamente'
                        : authProvider.error ?? 'Error desconocido'),
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

  void _logout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const DashboardTab({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClienteProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen General',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Estadísticas principales — Grid responsive para evitar overflow en pantallas pequeñas
              LayoutBuilder(
                builder: (context, constraints) {
                  // En pantallas muy angostas usar 1 columna, en pantallas pequeñas 2
                  final double maxWidth = constraints.maxWidth;
                  final int crossAxisCount = maxWidth < 480 ? 1 : 2;
                  final double childAspectRatio = maxWidth < 480 ? 3.2 : 1.5;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      DashboardCard(
                        title: 'Total Clientes',
                        value: provider.totalClientes.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                        onTap: () => _navigateToTab(context, 1),
                      ),
                      DashboardCard(
                        title: 'Clientes Activos',
                        value: provider.clientesActivos.toString(),
                        icon: Icons.person,
                        color: Colors.green,
                        onTap: () => _navigateToTab(context, 1),
                      ),
                      DashboardCard(
                        title: 'Cuotas Vencidas',
                        value: provider.cuotasVencidas.length.toString(),
                        icon: Icons.warning,
                        color: Colors.red,
                        onTap: () => _navigateToTab(context, 2),
                      ),
                      DashboardCard(
                        title: 'Próximos Vencimientos',
                        value: provider.cuotasProximas.length.toString(),
                        icon: Icons.schedule,
                        color: Colors.orange,
                        onTap: () => _navigateToTab(context, 2),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Lista de cuotas críticas
              if (provider.cuotasVencidas.isNotEmpty ||
                  provider.cuotasProximas.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atención Requerida',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    if (provider.cuotasVencidas.isNotEmpty) ...[
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.warning, color: Colors.red),
                          title: Text(
                            '${provider.cuotasVencidas.length} cuotas vencidas',
                          ),
                          subtitle: const Text('Requieren atención inmediata'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _navigateToTab(context, 2),
                        ),
                      ),
                    ],

                    if (provider.cuotasProximas.isNotEmpty) ...[
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.schedule,
                            color: Colors.orange,
                          ),
                          title: Text(
                            '${provider.cuotasProximas.length} cuotas próximas a vencer',
                          ),
                          subtitle: const Text(
                            'Vencen en los próximos 30 días',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _navigateToTab(context, 2),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    if (onNavigateToTab != null) {
      onNavigateToTab!(tabIndex);
    } else {
      // Fallback: mostrar mensaje si no se puede navegar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Dirígete a la pestaña correspondiente para ver más detalles',
          ),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }
}
