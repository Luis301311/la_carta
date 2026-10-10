import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:lacarta/core/models/dashboard.dart';
import 'package:lacarta/core/utils/format.dart';

/// Ventas de los últimos 7 días en barras (son días separados, por eso barras
/// y no línea). Hoy va en coral. Al tocar una barra se ve su detalle arriba.
class WeeklySalesChart extends StatefulWidget {
  final List<DaySales> days;
  final double barAreaHeight;
  const WeeklySalesChart({super.key, required this.days, this.barAreaHeight = 170});

  @override
  State<WeeklySalesChart> createState() => _WeeklySalesChartState();
}

class _WeeklySalesChartState extends State<WeeklySalesChart> {
  int? _selected;

  /// Tope "redondo" del eje: 48.000 -> 60.000
  static double _niceMax(double v) {
    if (v <= 0) return 10000;
    final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final m in [1, 2, 2.5, 3, 4, 5, 6, 8, 10]) {
      if (m * exp >= v) return m * exp;
    }
    return 10 * exp;
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    if (days.isEmpty) return const SizedBox.shrink();
    final selected = _selected ?? days.length - 1; // por defecto: hoy
    final maxSales = days.map((d) => d.sales).fold<double>(0, math.max);
    final top = _niceMax(maxSales);
    final h = widget.barAreaHeight;
    final sel = days[selected];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detalle del día seleccionado (en vez de un globo flotante)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.greenSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${selected == days.length - 1 ? 'Hoy' : '${Fmt.weekdayShort(sel.date)} ${Fmt.dayMonth(sel.date)}'}: '
            '${Fmt.money(sel.sales)} · ${sel.orders} pedido${sel.orders == 1 ? '' : 's'}',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.green, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: h + 46, // barras + etiquetas del eje X
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eje Y
              SizedBox(
                width: 46,
                height: h,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [top, top / 2, 0.0]
                      .map((v) => Text(Fmt.moneyShort(v),
                          style: const TextStyle(fontSize: 11, color: Colors.grey)))
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              // Barras
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: h,
                      child: Stack(
                        children: [
                          // Líneas guía
                          for (final f in [0.0, 0.5, 1.0])
                            Positioned(
                              left: 0,
                              right: 0,
                              top: f * (h - 1),
                              child: Container(height: 1, color: AppColors.border),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(days.length, (i) {
                              final d = days[i];
                              final isToday = i == days.length - 1;
                              final ratio = top == 0 ? 0.0 : d.sales / top;
                              final color = isToday ? AppColors.coral : AppColors.green;
                              return Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => setState(() => _selected = i),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: FractionallySizedBox(
                                      widthFactor: 0.55,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        // Mínimo 3 px para que se vea que el día existe
                                        height: math.max(3, h * ratio),
                                        decoration: BoxDecoration(
                                          color: i == selected
                                              ? color
                                              : color.withValues(alpha: 0.55),
                                          borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(6)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Eje X
                    Row(
                      children: days.map((d) {
                        final isSel = days.indexOf(d) == selected;
                        return Expanded(
                          child: Column(
                            children: [
                              Text(Fmt.weekdayShort(d.date),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          isSel ? FontWeight.w700 : FontWeight.w400)),
                              Text(Fmt.dayMonth(d.date),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
