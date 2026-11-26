// Métricas de reproducción (sin dependencias de Flutter).

/// Franja horaria en la que sonó una canción (hora local del oyente).
enum FranjaHoraria {
  madrugada, // 0 a 6
  manana, // 6 a 12
  tarde, // 12 a 19
  noche; // 19 a 24

  /// Franja de una hora del día (0..23).
  static FranjaHoraria de(int hora) {
    if (hora < 6) return madrugada;
    if (hora < 12) return manana;
    if (hora < 19) return tarde;
    return noche;
  }

  String get etiqueta => switch (this) {
    madrugada => 'Madrugada (0 a 6 hs)',
    manana => 'Mañana (6 a 12 hs)',
    tarde => 'Tarde (12 a 19 hs)',
    noche => 'Noche (19 a 24 hs)',
  };
}

/// Ciudad que se registra cuando el oyente no declaró ninguna (o es
/// invitado).
const String ciudadSinDeclarar = 'Sin declarar';

/// Normaliza la ciudad declarada para usarla como clave de las métricas:
/// sin espacios de más, sin caracteres que Firestore no acepta en nombres de
/// campo, y como máximo 40 caracteres. Vacía = [ciudadSinDeclarar].
String normalizarCiudad(String? ciudad) {
  final limpia = (ciudad ?? '')
      .replaceAll(RegExp(r'[.\/`\[\]*~]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (limpia.isEmpty) return ciudadSinDeclarar;
  return limpia.length > 40 ? limpia.substring(0, 40).trim() : limpia;
}

/// Contadores de una canción: total de reproducciones y cuántas fueron en
/// cada ciudad y en cada franja horaria (clave = `FranjaHoraria.name`).
///
/// Es el documento `metricas/{cancionId}` de Firestore, y también el
/// "incremento" que se le suma al sincronizar.
class MetricasCancion {
  const MetricasCancion({
    this.total = 0,
    this.ciudades = const {},
    this.franjas = const {},
  });

  /// Una sola reproducción en [ciudad] y [franja].
  factory MetricasCancion.una(String ciudad, FranjaHoraria franja) =>
      MetricasCancion(
        total: 1,
        ciudades: {normalizarCiudad(ciudad): 1},
        franjas: {franja.name: 1},
      );

  final int total;
  final Map<String, int> ciudades;
  final Map<String, int> franjas;

  bool get vacia => total == 0;

  /// Suma de las dos (no modifica ninguna).
  MetricasCancion sumar(MetricasCancion otra) => MetricasCancion(
    total: total + otra.total,
    ciudades: _sumarMapas(ciudades, otra.ciudades),
    franjas: _sumarMapas(franjas, otra.franjas),
  );

  Map<String, Object> toMap() => {
    'total': total,
    'ciudades': Map.of(ciudades),
    'franjas': Map.of(franjas),
  };

  /// Tolerante: campos faltantes o con otro tipo quedan en 0 / vacíos (un
  /// documento roto no debe tirar abajo las estadísticas).
  factory MetricasCancion.fromMap(Object? map) {
    if (map is! Map) return const MetricasCancion();
    Map<String, int> contadores(Object? v) => {
      if (v is Map)
        for (final e in v.entries)
          if (e.key is String && e.value is num && (e.value as num) > 0)
            e.key as String: (e.value as num).toInt(),
    };
    final total = map['total'];
    return MetricasCancion(
      total: total is num && total > 0 ? total.toInt() : 0,
      ciudades: contadores(map['ciudades']),
      franjas: contadores(map['franjas']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MetricasCancion &&
      other.total == total &&
      _mapasIguales(other.ciudades, ciudades) &&
      _mapasIguales(other.franjas, franjas);

  @override
  int get hashCode => Object.hash(
    total,
    Object.hashAllUnordered(ciudades.entries.map((e) => '${e.key}=${e.value}')),
    Object.hashAllUnordered(franjas.entries.map((e) => '${e.key}=${e.value}')),
  );

  @override
  String toString() => 'MetricasCancion($total, $ciudades, $franjas)';
}

/// Resumen para mostrar: total, ciudades de mayor a menor y la franja con
/// más reproducciones.
class ResumenMetricas {
  const ResumenMetricas({
    required this.total,
    required this.ciudades,
    required this.franjas,
  });

  final int total;

  /// Ciudades ordenadas de mayor a menor (empate: alfabético).
  final List<({String ciudad, int cantidad})> ciudades;

  /// Reproducciones por franja (todas las franjas, aunque estén en 0).
  final Map<FranjaHoraria, int> franjas;

  bool get vacio => total == 0;

  /// Franja con más reproducciones (null sin datos).
  FranjaHoraria? get franjaPico {
    FranjaHoraria? pico;
    for (final f in FranjaHoraria.values) {
      if ((franjas[f] ?? 0) > 0 &&
          (pico == null || franjas[f]! > franjas[pico]!)) {
        pico = f;
      }
    }
    return pico;
  }

  /// Proporción (0..1) de la franja [f] sobre el total.
  double proporcion(FranjaHoraria f) =>
      total == 0 ? 0 : (franjas[f] ?? 0) / total;
}

/// Junta las métricas de varias canciones (p. ej. todas las del artista) y
/// arma el resumen. Función pura sobre datos planos: se puede mandar a un
/// isolate (ver utils/procesador_isolate.dart).
ResumenMetricas resumirMetricas(Iterable<MetricasCancion> metricas) {
  var suma = const MetricasCancion();
  for (final m in metricas) {
    suma = suma.sumar(m);
  }
  final ciudades =
      [
        for (final e in suma.ciudades.entries)
          (ciudad: e.key, cantidad: e.value),
      ]..sort((a, b) {
        final c = b.cantidad.compareTo(a.cantidad);
        return c != 0 ? c : a.ciudad.compareTo(b.ciudad);
      });
  return ResumenMetricas(
    total: suma.total,
    ciudades: ciudades,
    franjas: {
      for (final f in FranjaHoraria.values) f: suma.franjas[f.name] ?? 0,
    },
  );
}

Map<String, int> _sumarMapas(Map<String, int> a, Map<String, int> b) {
  final r = Map.of(a);
  b.forEach((k, v) => r[k] = (r[k] ?? 0) + v);
  return r;
}

bool _mapasIguales(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
