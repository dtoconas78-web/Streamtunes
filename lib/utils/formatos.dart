// Agrega puntos de miles a un número entero (48302 -> "48.302").
String formatearMiles(int numero) {
  final texto = numero.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(texto[i]);
  }
  return buffer.toString();
}

// Formatea un precio con separador de miles y signo de pesos (15000 -> "$15.000").
String formatearPrecio(double valor) {
  final texto = valor.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (int i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(texto[i]);
  }
  return '\$$buffer';
}

// Formatea una fecha como "5 dic 2026".
String formatearFecha(DateTime f) {
  const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  return '${f.day} ${meses[f.month - 1]} ${f.year}';
}

// 4000 segundos -> "1 h 6 min"; 600 -> "10 min".
String formatearTotal(int segundos) {
  final minutos = segundos ~/ 60;
  if (minutos >= 60) return '${minutos ~/ 60} h ${minutos % 60} min';
  return '$minutos min';
}

// 1 -> "1 canción"; 3 -> "3 canciones".
String etiquetaCanciones(int cantidad) =>
    cantidad == 1 ? '1 canción' : '$cantidad canciones';
