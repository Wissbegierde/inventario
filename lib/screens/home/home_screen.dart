import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/movement_provider.dart';
import '../auth/login_screen.dart';
import '../products/products_list_screen.dart';
import '../movements/movements_list_screen.dart';
import '../suppliers/suppliers_list_screen.dart';
import '../reports/reports_screen.dart';
import '../reports/inventory_value_chart_screen.dart';
import '../../providers/alert_provider.dart';
import '../../models/alert.dart';
import '../../widgets/alerts_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialLoad = true;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    // Cargar datos después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    if (_hasLoadedData) return;
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final movementProvider = Provider.of<MovementProvider>(context, listen: false);
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);
    
    // Cargar productos si no están cargados
    if (productProvider.products.isEmpty && !productProvider.isLoading) {
      await productProvider.loadProducts();
    }
    
    // Cargar movimientos si no están cargados
    if (movementProvider.movements.isEmpty && !movementProvider.isLoading) {
      await movementProvider.loadMovements();
    }
    
    // Cargar alertas si no están cargadas
    if (alertProvider.alerts.isEmpty && !alertProvider.isLoading) {
      await alertProvider.loadAlerts();
    }
    
    // Generar alertas de stock bajo después de cargar productos
    if (productProvider.products.isNotEmpty) {
      await _generateLowStockAlerts(productProvider, alertProvider);
    }
    
    if (mounted) {
      setState(() {
        _hasLoadedData = true;
        _isInitialLoad = false;
      });
    }
  }
  
  Future<void> _generateLowStockAlerts(ProductProvider productProvider, AlertProvider alertProvider) async {
    // Esperar a que las alertas se carguen primero
    if (alertProvider.alerts.isEmpty && !alertProvider.isLoading) {
      await alertProvider.loadAlerts();
    }
    
    final lowStockProducts = productProvider.products.where((p) => p.tieneStockBajo).toList();
    
    for (final product in lowStockProducts) {
      // Verificar si ya existe una alerta no leída para este producto
      final existingAlert = alertProvider.alerts.where(
        (alert) => alert.productoId == product.id && 
                   alert.tipo == AlertType.stockBajo && 
                   !alert.leida,
      ).firstOrNull;
      
      // Solo crear alerta si no existe una activa
      if (existingAlert == null) {
        final alert = Alert(
          id: '',
          tipo: AlertType.stockBajo,
          titulo: 'Stock Bajo - ${product.nombre}',
          mensaje: 'El producto "${product.nombre}" tiene stock bajo (${product.stockActual} unidades). Stock mínimo: ${product.stockMinimo}',
          productoId: product.id,
          leida: false,
          fechaCreacion: DateTime.now(),
        );
        
        await alertProvider.createAlert(alert);
      }
    }
  }

  Future<void> _handleRefresh() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final movementProvider = Provider.of<MovementProvider>(context, listen: false);
    
    await Future.wait([
      productProvider.loadProducts(),
      movementProvider.loadMovements(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StockMaster PyME'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const AlertsMenu(),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(FontAwesomeIcons.user),
                onSelected: (value) {
                  if (value == 'profile') {
                    _handleProfile(context, authProvider);
                  } else if (value == 'logout') {
                    _handleLogout(context, authProvider);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(FontAwesomeIcons.user, size: 16),
                        const SizedBox(width: 8),
                        Text(authProvider.currentUser?.nombre ?? 'Usuario'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(FontAwesomeIcons.signOut, size: 16),
                        SizedBox(width: 8),
                        Text('Cerrar Sesión'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.white,
            backgroundColor: const Color(0xFF667eea),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildStatsCards(),
                  const SizedBox(height: 24), // Espacio extra al final
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      FontAwesomeIcons.hand,
                      color: const Color(0xFF667eea),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola, ${authProvider.currentUser?.nombre ?? 'Usuario'}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bienvenido a StockMaster PyME',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: FontAwesomeIcons.boxesStacked,
                title: 'Productos',
                subtitle: 'Gestionar inventario',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProductsListScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: FontAwesomeIcons.arrowRightArrowLeft,
                title: 'Movimientos',
                subtitle: 'Ver historial',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MovementsListScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: FontAwesomeIcons.truck,
                title: 'Proveedores',
                subtitle: 'Gestionar proveedores',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SuppliersListScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: FontAwesomeIcons.chartBar,
                title: 'Reportes',
                subtitle: 'Generar PDFs',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Consumer2<ProductProvider, MovementProvider>(
      builder: (context, productProvider, movementProvider, child) {
        // Mostrar loading si es la carga inicial
        if (_isInitialLoad && (productProvider.isLoading || movementProvider.isLoading)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCardSkeleton()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCardSkeleton()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCardSkeleton()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCardSkeleton()),
                ],
              ),
            ],
          );
        }

        final totalProducts = productProvider.totalProducts;
        final lowStockCount = productProvider.lowStockCount;
        final totalValue = productProvider.totalInventoryValue;
        final movementsToday = movementProvider.movementsToday;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Productos',
                    value: totalProducts.toString(),
                    icon: FontAwesomeIcons.boxesStacked,
                    color: const Color(0xFF10B981),
                    onTap: () {
                      // Navegar a la lista de productos
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProductsListScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Stock Bajo',
                    value: lowStockCount.toString(),
                    icon: FontAwesomeIcons.exclamationTriangle,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      // Navegar a la lista de productos con stock bajo
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProductsListScreen(showLowStockOnly: true),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Valor Inventario',
                    value: '\$${totalValue.toStringAsFixed(2)}',
                    icon: FontAwesomeIcons.dollarSign,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      // Navegar a la gráfica del valor del inventario
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const InventoryValueChartScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Movimientos Hoy',
                    value: movementsToday.toString(),
                    icon: FontAwesomeIcons.arrowRightArrowLeft,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Icon(
                FontAwesomeIcons.chevronRight,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );

    // Si hay onTap, hacer la tarjeta clickeable
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }

  void _handleProfile(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perfil de Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileInfo('Nombre', authProvider.currentUser?.nombre ?? 'N/A'),
            const SizedBox(height: 8),
            _buildProfileInfo('Email', authProvider.currentUser?.email ?? 'N/A'),
            const SizedBox(height: 8),
            _buildProfileInfo('Rol', authProvider.currentUser?.rol ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF667eea),
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  static void _handleLogout(BuildContext context, AuthProvider authProvider) async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        // Navegar al login y limpiar el stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

}
