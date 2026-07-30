import 'package:flutter/material.dart';

class AppFloatingButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final String? heroTag;
  final String? tooltip;

  const AppFloatingButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.isLoading,
    this.backgroundColor,
    this.textColor,
    this.heroTag,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? Colors.white,
                ),
              ),
            )
          : Icon(
              icon,
              color: textColor,
            ),
      label: Text(
        isLoading ? "Cargando..." : text,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
      ),
    );
  }
}