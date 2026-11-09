// Convierte "3:24" en segundos (204).
int aSegundos(String duracion) {
  final partes = duracion.split(':');
  return int.parse(partes[0]) * 60 + int.parse(partes[1]);
}

// Convierte segundos en "m:ss" (204 -> "3:24").
String formatoTiempo(int segundos) {
  final minutos = segundos ~/ 60;
  final resto = (segundos % 60).toString().padLeft(2, '0');
  return '$minutos:$resto';
}
