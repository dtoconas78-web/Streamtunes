// Regla de negocio de la comisión (función pura, sin dependencias).

/// Comisión de la plataforma por cada entrada vendida: StreamTunes se queda
/// con este porcentaje de lo que recibe el artista. El fan paga el precio
/// publicado (sin cargos extra). Las donaciones NO tienen comisión.
const double comisionEntradas = 0.30;

/// Comisión de StreamTunes sobre [monto] (redondeada a centavos).
double comisionDe(double monto) =>
    (monto * comisionEntradas * 100).roundToDouble() / 100;

/// Porcentaje de comisión para mostrar (p. ej. "30%").
String get porcentajeComision => '${(comisionEntradas * 100).round()}%';
