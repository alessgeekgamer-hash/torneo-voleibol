import 'models.dart';

/// Reglas oficiales FIVB simplificadas e implementadas en la app:
/// - Sets normales a 25, definitivo a 15, diferencia de 2 sin tope.
/// - Tiempos: 2 tiempos de 30s por set por equipo.
/// - Sustituciones: 6 por set por equipo. Un titular puede salir y
///   reingresar UNA vez en el mismo set, y solo por el jugador que lo
///   sustituyó. Un sustituto que ya salió no puede volver a entrar en el
///   mismo set (salvo lesión/excepción que aquí se bloquea y se sugiere
///   sustitución excepcional manual).

bool ganaSet(int a, int b, int setNum, Formato f) {
  final target = puntosParaSet(setNum, f);
  if (a < target && b < target) return false;
  final diff = (a - b).abs();
  if (diff < 2) return false;
  return true;
}

bool puedePedirTiempo(int usados) => usados < 2;

/// FIVB: el saque inicial alterna entre sets. El equipo que abrió el saque
/// en un set NO lo abre en el siguiente (le toca al otro).
String saqueDelSiguienteSet(
    String saqueInicioSet, String ladoAId, String ladoBId) {
  if (saqueInicioSet != ladoAId && saqueInicioSet != ladoBId) {
    return ladoAId; // dato faltante/extraño: no cambia nada.
  }
  return saqueInicioSet == ladoAId ? ladoBId : ladoAId;
}

/// FIVB: los equipos cambian de lado después de cada set.
bool ladoDelSiguienteSet(bool ladoInvertido) => !ladoInvertido;

class ControlSustituciones {
  ControlSustituciones();
  int usadas = 0;
  // titularId -> sustitutoId actual
  final Map<String, String> titularASustituto = {};
  // sustitutoId -> titularId origen
  final Map<String, String> sustitutoATitular = {};
  // jugadores que ya salieron y no pueden volver (sustitutos usados)
  final Set<String> bloqueados = {};
  // titulares que ya usaron su reingreso
  final Set<String> reingresoUsado = {};

  bool get puedeSustituir => usadas < 6;

  Map<String, dynamic> toJson() => {
        'usadas': usadas,
        'titularASustituto': titularASustituto,
        'sustitutoATitular': sustitutoATitular,
        'bloqueados': bloqueados.toList(),
        'reingresoUsado': reingresoUsado.toList(),
      };
  factory ControlSustituciones.desdeJson(Map<String, dynamic> j) {
    final c = ControlSustituciones();
    c.usadas = (j['usadas'] ?? 0) as int;
    final t2s = Map<String, dynamic>.from(j['titularASustituto'] ?? {});
    t2s.forEach((k, v) => c.titularASustituto[k] = '$v');
    final s2t = Map<String, dynamic>.from(j['sustitutoATitular'] ?? {});
    s2t.forEach((k, v) => c.sustitutoATitular[k] = '$v');
    c.bloqueados
        .addAll(((j['bloqueados'] ?? []) as List).map((e) => '$e'));
    c.reingresoUsado
        .addAll(((j['reingresoUsado'] ?? []) as List).map((e) => '$e'));
    return c;
  }

  /// Lista de jugadores de banca que pueden entrar por [saleId].
  List<String> entradasLegalesPara(
      String saleId, List<String> banca, Set<String> titularesIniciales) {
    if (!puedeSustituir) return [];
    final enCanchaSub = sustitutoATitular[saleId];
    if (titularesIniciales.contains(saleId)) {
      // Titular en cancha: no puede salir si ya usó su reingreso.
      if (reingresoUsado.contains(saleId)) return [];
      if (titularASustituto.containsKey(saleId)) return [];
      // Solo banca fresca: excluye bloqueados y titulares en espera de reingreso.
      return banca
          .where((e) =>
              !bloqueados.contains(e) &&
              !titularesIniciales.contains(e))
          .toList();
    }
    // Sustituto en cancha: solo puede salir por su titular original.
    if (enCanchaSub != null) {
      if (reingresoUsado.contains(enCanchaSub)) return [];
      if (banca.contains(enCanchaSub)) return [enCanchaSub];
      return [];
    }
    return [];
  }

  /// Lista de jugadores activos que pueden salir para que entre [entraId].
  List<String> salidasLegalesPara(
      String entraId, List<String> activos, Set<String> titularesIniciales) {
    if (!puedeSustituir) return [];
    if (bloqueados.contains(entraId)) return [];
    if (titularesIniciales.contains(entraId)) {
      // Titular en banca: solo puede volver por su propio sustituto.
      final sub = titularASustituto[entraId];
      if (sub != null && activos.contains(sub)) {
        if (reingresoUsado.contains(entraId)) return [];
        return [sub];
      }
      return [];
    }
    // Banca fresca: puede entrar por cualquier titular en cancha
    // sin sustituto activo y sin reingreso usado.
    return activos
        .where((a) =>
            titularesIniciales.contains(a) &&
            !titularASustituto.containsKey(a) &&
            !reingresoUsado.contains(a))
        .toList();
  }

  /// Valida si [saleId] puede ser sustituido por [entraId].
  String? validar(String saleId, String entraId, Set<String> titularesIniciales) {
    if (usadas >= 6) return 'Máximo 6 sustituciones por set (FIVB).';
    if (saleId == entraId) return 'Selecciona jugadores distintos.';
    if (bloqueados.contains(entraId)) {
      return 'Ese jugador ya salió en este set y no puede reingresar (FIVB).';
    }
    // Si el que sale es un titular inicial
    final esTitular = titularesIniciales.contains(saleId);
    if (esTitular) {
      if (reingresoUsado.contains(saleId)) {
        return 'Ese titular ya usó su reingreso y no puede salir de nuevo (FIVB).';
      }
      // ¿ya tiene un sustituto activo? entonces es reingreso del titular?
      // Caso: sale el sustituto para que vuelva el titular.
      return null;
    }
    // Si el que sale NO es titular (es sustituto), y entra el titular original: es reingreso permitido una vez.
    final origen = sustitutoATitular[saleId];
    if (origen != null) {
      if (entraId != origen) {
        return 'El sustituto solo puede ser reemplazado por el titular original (FIVB).';
      }
      if (reingresoUsado.contains(entraId)) {
        return 'El titular ya usó su reingreso en este set.';
      }
      return null;
    }
    // Si sale un sustituto para que entre otro sustituto nuevo: no permitido
    // (el titular debe volver primero).
    if (!esTitular && origen == null) {
      // entra otro banca que nunca ha entrado: solo permitido si el que sale
      // es titular. Como no lo es, bloquear.
      return 'Solo el titular original puede reemplazar a su sustituto (FIVB).';
    }
    return null;
  }

  void registrar(String saleId, String entraId, Set<String> titularesIniciales) {
    usadas++;
    final esTitularSale = titularesIniciales.contains(saleId);
    if (esTitularSale) {
      titularASustituto[saleId] = entraId;
      sustitutoATitular[entraId] = saleId;
    } else {
      // reingreso del titular
      final origen = sustitutoATitular[saleId];
      if (origen != null && entraId == origen) {
        reingresoUsado.add(entraId);
        bloqueados.add(saleId);
        titularASustituto.remove(entraId);
        sustitutoATitular.remove(saleId);
      }
    }
  }
}

/// Rota en sentido de las manecillas: 2->1, 3->2, 4->3, 5->4, 6->5, 1->6.
/// La lista representa índices 0..5 = posiciones 1..6.
List<String> rotar(List<String> pos1a6) {
  if (pos1a6.length != 6) return pos1a6;
  // pos1 = idx0, pos2=idx1, ... pos6=idx5
  // nuevo1 = viejo2, nuevo2=v viejo3, nuevo3=v4, nuevo4=v5, nuevo5=v6, nuevo6=v1
  return [
    pos1a6[1],
    pos1a6[2],
    pos1a6[3],
    pos1a6[4],
    pos1a6[5],
    pos1a6[0],
  ];
}
