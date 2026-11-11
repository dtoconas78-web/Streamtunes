// Convierte segundos en "m:ss" (204 -> "3:24").
// La duración se guarda como int en el modelo; el formato es cosa de la UI.
String formatoTiempo(int segundos) {
  final minutos = segundos ~/ 60;
  final resto = (segundos % 60).toString().padLeft(2, '0');
  return '$minutos:$resto';
}
