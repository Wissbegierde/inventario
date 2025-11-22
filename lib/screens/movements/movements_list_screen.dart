import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/movement_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/movement.dart';
import '../../widgets/movement_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/movement_stats_card.dart';
import 'movement_form_screen.dart';

class MovementsListScreen extends StatefulWidget {
  final bool showTodayOnly;
  
  const MovementsListScreen({super.key, this.showTodayOnly = false});

  @override
  State<MovementsListScreen> createState() => _MovementsListScreenState();
}

class _MovementsListScreenState extends State<MovementsListScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialLoad = true;
  bool _hasCompletedInitialLoad = false;
  MovementProvider? _movementProvider;
  bool _isLoadingMovements = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _movementProvider = Provider.of<MovementProvider>(context, listen: false);
        _movementProvider!.addListener(_onProviderChanged);
        
        // Cargar productos primero (necesarios para calcular dinero ganado)
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        if (productProvider.products.isEmpty && !productProvider.isLoading) {
          productProvider.loadProducts();
        }
        
        _loadMovements();
      }
    });
  }

  Future<void> _loadMovementsToday() async {
    if (_isLoadingMovements) return;
    
    _isLoadingMovements = true;
    try {
      final movementProvider = Provider.of<MovementProvider>(context, listen: false);
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      await movementProvider.filterByDateRange(todayStart, todayEnd);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMovements = false;
        });
      }
    }
  }

  void _onProviderChanged() {
    if (!mounted || _movementProvider == null) return;
    
    if (!_hasCompletedInitialLoad && _isInitialLoad) {
      if (!_movementProvider!.isLoading) {
        _hasCompletedInitialLoad = true;
        Future.microtask(() {
          if (mounted && _isInitialLoad) {
            setState(() {
              _isInitialLoad = false;
            });
          }
        });
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  Future<void> _loadMovements() async {
    if (_isLoadingMovements) return;
    
    _isLoadingMovements = true;
    try {
      final movementProvider = Provider.of<MovementProvider>(context, listen: false);
      
      // Si se solicita mostrar solo movimientos de hoy, filtrar por fecha
      if (widget.showTodayOnly) {
        await _loadMovementsToday();
      } else {
        await movementProvider.loadMovements();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMovements = false;
        });
      }
    }
  }

  void _handleSearch(String query) {
    final movementProvider = Provider.of<MovementProvider>(context, listen: false);
    movementProvider.searchMovements(query);
  }

  Future<void> _handleTypeFilter(MovementType? type) async {
    final movementProvider = Provider.of<MovementProvider>(context, listen: false);
    await movementProvider.filterByType(type);
  }

  Future<void> _clearFilters() async {
    _searchController.clear();
    final movementProvider = Provider.of<MovementProvider>(context, listen: false);
    movementProvider.clearFilters();
    await _loadMovements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _movementProvider?.removeListener(_onProviderChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showTodayOnly ? 'Movimientos de Hoy' : 'Historial de Movimientos'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(FontAwesomeIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
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
          child: Column(
            children: [
              // Barra de búsqueda y filtros
              _buildSearchAndFilters(),
              // Lista de movimientos
              Expanded(
                child: Consumer<MovementProvider>(
                  builder: (context, movementProvider, child) {
                    final isLoading = movementProvider.isLoading;
                    final hasMovements = movementProvider.movements.isNotEmpty;
                    final shouldShowSkeleton = _isInitialLoad && isLoading;
                    
                    if (shouldShowSkeleton) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    }
                    
                    return RefreshIndicator(
                      onRefresh: _loadMovements,
                      color: const Color(0xFF667eea),
                      child: _buildMovementsList(movementProvider, hasMovements),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MovementFormScreen(),
            ),
          ).then((_) => _loadMovements());
        },
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(FontAwesomeIcons.plus),
        label: const Text('Nuevo Movimiento'),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            onChanged: _handleSearch,
            decoration: InputDecoration(
              hintText: 'Buscar por producto, motivo o usuario...',
              prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 16),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(FontAwesomeIcons.xmark, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        _handleSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Filtros por tipo
          Consumer<MovementProvider>(
            builder: (context, movementProvider, child) {
              return Row(
                children: [
                  Expanded(
                    child: _buildTypeChip(
                      'Todos',
                      movementProvider.selectedType == null,
                      () => _handleTypeFilter(null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeChip(
                      'Entrada',
                      movementProvider.selectedType == MovementType.entrada,
                      () => _handleTypeFilter(MovementType.entrada),
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeChip(
                      'Salida',
                      movementProvider.selectedType == MovementType.salida,
                      () => _handleTypeFilter(MovementType.salida),
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              );
            },
          ),
              // Indicador de resultados
          Consumer<MovementProvider>(
            builder: (context, movementProvider, child) {
              // Calcular contadores según si estamos mostrando solo hoy o todos
              int filteredCount;
              int totalCount;
              
              if (widget.showTodayOnly) {
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final todayEnd = todayStart.add(const Duration(days: 1));
                
                final todayMovements = movementProvider.movements.where((movement) {
                  final movementDate = movement.fecha;
                  return movementDate.isAfter(todayStart) && movementDate.isBefore(todayEnd);
                }).toList();
                
                totalCount = todayMovements.length;
                filteredCount = todayMovements.where((m) {
                  if (movementProvider.selectedType != null && m.tipo != movementProvider.selectedType) {
                    return false;
                  }
                  if (movementProvider.searchQuery.isNotEmpty) {
                    final query = movementProvider.searchQuery.toLowerCase();
                    final productoNombre = (m.productoNombre ?? '').toLowerCase();
                    final motivo = m.motivo.toLowerCase();
                    final usuarioNombre = (m.usuarioNombre ?? '').toLowerCase();
                    if (!productoNombre.contains(query) && 
                        !motivo.contains(query) && 
                        !usuarioNombre.contains(query)) {
                      return false;
                    }
                  }
                  return true;
                }).length;
              } else {
                filteredCount = movementProvider.filteredMovements.length;
                totalCount = movementProvider.movements.length;
              }
              
              if (totalCount == 0) {
                return const SizedBox.shrink();
              }
              
              final hasFilters = widget.showTodayOnly || 
                  movementProvider.selectedType != null ||
                  movementProvider.selectedProductId != null ||
                  movementProvider.startDate != null ||
                  movementProvider.searchQuery.isNotEmpty;
              
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      filteredCount == totalCount
                          ? '$totalCount movimiento${totalCount != 1 ? 's' : ''}'
                          : '$filteredCount de $totalCount movimiento${totalCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasFilters && !widget.showTodayOnly)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(FontAwesomeIcons.xmark, size: 12),
                        label: const Text('Limpiar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, bool isSelected, VoidCallback onTap, {Color? color}) {
    final chipColor = color ?? const Color(0xFF6B7280);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovementsList(MovementProvider movementProvider, bool hasMovements) {
    // Si showTodayOnly es true, filtrar solo movimientos de hoy
    List<Movement> movementsToShow;
    if (widget.showTodayOnly) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      // Obtener movimientos base
      var baseMovements = List<Movement>.from(movementProvider.movements);
      
      // Filtrar por fecha de hoy
      baseMovements = baseMovements.where((movement) {
        final movementDate = movement.fecha;
        return movementDate.isAfter(todayStart) && movementDate.isBefore(todayEnd);
      }).toList();
      
      // Aplicar filtros adicionales si existen
      if (movementProvider.selectedType != null) {
        baseMovements = baseMovements.where((m) => m.tipo == movementProvider.selectedType).toList();
      }
      
      if (movementProvider.searchQuery.isNotEmpty) {
        final query = movementProvider.searchQuery.toLowerCase();
        baseMovements = baseMovements.where((movement) {
          final productoNombre = (movement.productoNombre ?? '').toLowerCase();
          final motivo = movement.motivo.toLowerCase();
          final usuarioNombre = (movement.usuarioNombre ?? '').toLowerCase();
          return productoNombre.contains(query) ||
                 motivo.contains(query) ||
                 usuarioNombre.contains(query);
        }).toList();
      }
      
      movementsToShow = baseMovements;
    } else {
      movementsToShow = movementProvider.filteredMovements;
    }
    
    final hasFilteredMovements = movementsToShow.isNotEmpty;
    
    if (!hasMovements) {
      return EmptyState(
        icon: FontAwesomeIcons.arrowRightArrowLeft,
        title: 'No hay movimientos',
        message: 'Aún no se han registrado movimientos de inventario.\nCrea uno nuevo para comenzar.',
        actionLabel: 'Registrar Movimiento',
        onAction: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MovementFormScreen(),
            ),
          ).then((_) => _loadMovements());
        },
      );
    }
    
    if (!hasFilteredMovements) {
      return EmptyState(
        icon: FontAwesomeIcons.magnifyingGlass,
        title: widget.showTodayOnly ? 'No hay movimientos hoy' : 'No se encontraron resultados',
        message: widget.showTodayOnly 
            ? 'No se han registrado movimientos el día de hoy.\nIntenta crear un nuevo movimiento.'
            : 'No hay movimientos que coincidan con tu búsqueda.\nIntenta con otros términos o limpia los filtros.',
        actionLabel: widget.showTodayOnly ? 'Registrar Movimiento' : 'Limpiar Filtros',
        onAction: widget.showTodayOnly ? () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MovementFormScreen(),
            ),
          ).then((_) => _loadMovements());
        } : _clearFilters,
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: movementsToShow.length + 1, // +1 para la tarjeta de estadísticas
        itemBuilder: (context, index) {
          // Mostrar estadísticas al inicio
          if (index == 0) {
            return MovementStatsCard(movementProvider: movementProvider);
          }
          
          // Mostrar movimientos
          final movement = movementsToShow[index - 1];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: MovementCard(
              movement: movement,
              onTap: () {
                // TODO: Navegar a detalle de movimiento
                // Por ahora, solo mostramos un snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Movimiento: ${movement.productoNombre ?? "N/A"}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

