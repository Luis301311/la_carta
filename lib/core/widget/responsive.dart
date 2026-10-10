import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Medidas compartidas para que el menú se vea bien en celular, tablet y PC.
class Responsive {
  /// Ancho máximo del contenido del menú. En pantallas más anchas el menú
  /// queda centrado, como una app móvil, en vez de estirarse.
  static const double maxContentWidth = 720;

  /// Ancho útil del contenido: el de la pantalla, pero sin pasar de [max].
  /// Se usa en lugar de LayoutBuilder dentro de listas/slivers: LayoutBuilder
  /// ahí (sobre todo con Obx adentro) dispara el error
  /// "_debugRelayoutBoundaryAlreadyMarkedNeedsLayout".
  static double contentWidth(BuildContext context,
          [double max = maxContentWidth]) =>
      math.min(MediaQuery.sizeOf(context).width, max);

  static bool isSmall(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;
}

/// Centra el contenido y limita su ancho a [maxWidth], ocupando todo el alto.
/// Úsalo como `body` de las pantallas del cliente.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox.expand(
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
