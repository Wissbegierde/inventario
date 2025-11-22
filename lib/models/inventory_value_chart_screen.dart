import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_value_history_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/movement_provider.dart';
import '../../models/inventory_value_history.dart';

class InventoryValueChartScreen extends StatefulWidget {
  const InventoryValueChartScreen({super.key});

  @override
  State<InventoryValueChartScreen> createState() => _InventoryValueChartScreenState();
}

class _InventoryValueChartScreenState extends State<InventoryValueChartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final historyProvider = Provider.of<InventoryValueHistoryProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final movementProvider = Provider.of<MovementProvider>(context, listen: false);

    await historyProvider.loadHistoryData(
      productProvider: productProvider,
      movementProvider: movementProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valor del Inventario'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(FontAwesomeIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: false,
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
              _buildPeriodFilters(),
              Expanded(
                child: Consumer<InventoryValueHistoryProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    }

                    if (provider.errorMessage != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                FontAwesomeIcons.exclamationTriangle,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.errorMessage!,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (provider.historyData.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay datos disponibles',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildChartCard(provider),
                          const SizedBox(height: 16),
                          _buildStatsCard(provider),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilters() {
    return Consumer<InventoryValueHistoryProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPeriodButton(
                context,
                'Día',
                TimePeriod.day,
                provider.selectedPeriod == TimePeriod.day,
                onTap: () => _changePeriod(TimePeriod.day),
              ),
              _buildPeriodButton(
                context,
                'Semana',
                TimePeriod.week,
                provider.selectedPeriod == TimePeriod.week,
                onTap: () => _changePeriod(TimePeriod.week),
              ),
              _buildPeriodButton(
                context,
                'Mes',
                TimePeriod.month,
                provider.selectedPeriod == TimePeriod.month,
                onTap: () => _changePeriod(TimePeriod.month),
              ),
              _buildPeriodButton(
                context,
                'Año',
                TimePeriod.year,
                provider.selectedPeriod == TimePeriod.year,
                onTap: () => _changePeriod(TimePeriod.year),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodButton(
    BuildContext context,
    String label,
    TimePeriod period,
    bool isSelected, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _changePeriod(TimePeriod period) async {
    final historyProvider = Provider.of<InventoryValueHistoryProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final movementProvider = Provider.of<MovementProvider>(context, listen: false);

    await historyProvider.loadHistoryData(
      productProvider: productProvider,
      movementProvider: movementProvider,
      period: period,
    );
  }

  Widget _buildChartCard(InventoryValueHistoryProvider provider) {
    final data = provider.historyData;
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final chartMax = maxValue + (range * 0.1);
    final chartMin = (minValue - (range * 0.1)).clamp(0.0, double.infinity);
    
    // Calcular intervalos asegurando que no sean cero
    final verticalRange = chartMax - chartMin;
    final horizontalInterval = verticalRange > 0 ? (verticalRange / 5).clamp(0.1, double.infinity) : 1.0;
    final leftInterval = horizontalInterval;
    
    // Calcular intervalo para el eje X basándose en el número de puntos y el período
    double bottomInterval;
    int maxLabels;
    switch (provider.selectedPeriod) {
      case TimePeriod.day:
        maxLabels = 6; // Máximo 6 labels para 24 horas
        break;
      case TimePeriod.week:
        maxLabels = 7; // 7 días
        break;
      case TimePeriod.month:
        maxLabels = 10; // Máximo 10 labels para 30 días
        break;
      case TimePeriod.year:
        maxLabels = 12; // 12 meses
        break;
    }
    bottomInterval = (data.length / maxLabels).ceil().toDouble().clamp(1.0, double.infinity);

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
          const Text(
            'Evolución del Valor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: bottomInterval,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return _buildBottomTitle(data[index].date, provider.selectedPeriod);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      interval: leftInterval,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '\$${_formatValue(value)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: chartMin,
                maxY: chartMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.value);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: true,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildBottomTitle(DateTime date, TimePeriod period) {
    String format;
    switch (period) {
      case TimePeriod.day:
        format = 'HH:mm';
        break;
      case TimePeriod.week:
        format = 'dd/MM';
        break;
      case TimePeriod.month:
        format = 'dd/MM';
        break;
      case TimePeriod.year:
        format = 'MMM';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        DateFormat(format).format(date),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 9,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatsCard(InventoryValueHistoryProvider provider) {
    final data = provider.historyData;
    if (data.isEmpty) return const SizedBox.shrink();

    final currentValue = data.last.value;
    final previousValue = data.length > 1 ? data[data.length - 2].value : currentValue;
    final change = currentValue - previousValue;
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final avgValue = data.map((e) => e.value).reduce((a, b) => a + b) / data.length;

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
          const Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Valor Actual',
                  '\$${currentValue.toStringAsFixed(2)}',
                  const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Cambio',
                  '${change >= 0 ? '+' : ''}\$${change.toStringAsFixed(2)}',
                  change >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Máximo',
                  '\$${maxValue.toStringAsFixed(2)}',
                  Colors.grey[700]!,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Mínimo',
                  '\$${minValue.toStringAsFixed(2)}',
                  Colors.grey[700]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Promedio',
            '\$${avgValue.toStringAsFixed(2)}',
            Colors.grey[700]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

