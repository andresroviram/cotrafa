abstract final class FormatUtils {
  /// Formatea una cifra de población con sufijos K/M para legibilidad.
  /// Ejemplos: 1 500 000 → '1.5M', 45 000 → '45K', 800 → '800'
  static String formatPopulation(int population) {
    if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)}M';
    }
    if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(0)}K';
    }
    return population.toString();
  }

  /// Formatea un entero con separadores de miles usando punto.
  /// Ejemplo: 1500000 → '1.500.000'
  static String formatNumber(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
