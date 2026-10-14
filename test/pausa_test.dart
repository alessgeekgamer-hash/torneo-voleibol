import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_voleibol/models.dart';
import 'package:torneo_voleibol/rules.dart';

void main() {
  test('Pausa guarda y restaura el punto exacto', () {
    final sub = ControlSustituciones();
    const tit = {'t1', 't2', 't3', 't4', 't5', 't6'};
    sub.registrar('t1', 'b1', tit);

    final pausa = PausaPartido(
      torneoId: 'tor1',
      matchId: 'match1',
      ladoAId: 'eqA',
      ladoBId: 'eqB',
      sacaId: 'eqA',
      setNumero: 2,
      pA: 14,
      pB: 12,
      tA: 1,
      tB: 2,
      posA: ['a1', 'a2', 'a3', 'a4', 'a5', 'a6'],
      posB: ['b1', 'b2', 'b3', 'b4', 'b5', 'b6'],
      subA: sub.toJson(),
      subB: ControlSustituciones().toJson(),
      ladoInvertido: true,
      cambioHecho: false,
      accSetsFA: 1,
      accSetsFB: 0,
      accParciales: ['25-20'],
      accSanciones: [],
      accJugA: ['a1'],
      accJugB: ['b1'],
      accTiemposA: [1],
      accTiemposB: [0],
      accCambiosA: [2],
      accCambiosB: [1],
      ladoAOrig: 'eqA',
      ladoBOrig: 'eqB',
      saqueOrig: 'eqA',
      titA: ['t1', 't2', 't3', 't4', 't5', 't6'],
      titB: ['u1', 'u2', 'u3', 'u4', 'u5', 'u6'],
    );

    final copia =
        PausaPartido.fromJson(pausa.toJson());
    expect(copia.setNumero, 2);
    expect(copia.pA, 14);
    expect(copia.pB, 12);
    expect(copia.tA, 1);
    expect(copia.posA, ['a1', 'a2', 'a3', 'a4', 'a5', 'a6']);
    expect(copia.ladoInvertido, true);
    expect(copia.accSetsFA, 1);
    expect(copia.accParciales, ['25-20']);
    expect(copia.accTiemposA, [1]);
    expect(copia.accCambiosA, [2]);
    expect(copia.titA.length, 6);

    final subRec =
        ControlSustituciones.desdeJson(copia.subA);
    expect(subRec.usadas, 1);
    // t1 salió por b1: b1 solo puede salir por t1
    expect(subRec.entradasLegalesPara('b1', ['t1', 'b2'], tit),
        ['t1']);
    // b2 fresco no puede entrar por b1 (sustituto en cancha)
    expect(
        subRec.salidasLegalesPara('b2', ['b1', 't2'], tit),
        ['t2']);
  });
}
