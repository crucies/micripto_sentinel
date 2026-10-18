import 'package:flutter/material.dart';

class AppColors {
  // Lienzo y Superficies Neo-Brutalistas "Money Magnet"
  static const Color background = Color(0xFFFFF8E7); // Crema Solar / Lingote
  static const Color surface = Color(0xFFFFFFFF); // Blanco Puro
  static const Color surfaceLight = Color(0xFFFFF3C4); // Amarillo Crema para celdas
  static const Color card = Color(0xFFFFFFFF); // Blanco Puro
  static const Color ink = Color(0xFF0A0A0A); // Negro Carbón Brutalista
  static const Color border = Color(0xFF0A0A0A); // Borde Sólido Negro

  // Colores que "Llaman Dinero" (Blanco, Amarillo Oro, Naranja Fuego)
  static const Color gold = Color(0xFFFFD600); // Amarillo Oro Riqueza
  static const Color amber = Color(0xFFFF9500); // Ámbar Dorado Intenso
  static const Color orange = Color(0xFFFF5500); // Naranja Fuego / Acción Dinero
  static const Color orangeSoft = Color(0xFFFFEDD5); // Crema Naranja Suave

  // Acentos Semánticos y Compatibilidad
  static const Color cyan = Color(0xFFFF5500); // Acento Primario Táctico -> Naranja Dinero
  static const Color emerald = Color(0xFF047857); // Verde Dólar Profundo
  static const Color rose = Color(0xFFD9381E); // Rojo/Naranja Alerta

  // Tipografía de Alto Contraste sobre Claro/Oro
  static const Color textPrimary = Color(0xFF0A0A0A); // Negro Puro
  static const Color textSecondary = Color(0xFF451A03); // Bronce Oscuro
  static const Color textMuted = Color(0xFF78350F); // Ámbar Profundo

  /// Decorador DRY para Tarjetas y Botones Neo-Brutalistas con Sombra Dura Sólida
  static BoxDecoration brutalistBox({
    Color color = surface,
    Color borderColor = ink,
    double borderWidth = 2.5,
    double shadowOffset = 5.0,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: borderColor,
          offset: Offset(shadowOffset, shadowOffset),
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Decorador DRY para Celdas Internas de Grilla Brutalista (Sin sombra exterior)
  static BoxDecoration brutalistCell({
    Color color = surfaceLight,
    Color borderColor = ink,
    double borderWidth = 2.0,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: borderColor, width: borderWidth),
    );
  }
}
