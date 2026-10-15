import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_voleibol/responsive.dart';

void main() {
  test('Columnas según ancho', () {
    expect(Resp.cols(360), 2); // celular
    expect(Resp.cols(600), 2); // tableta vertical
    expect(Resp.cols(800), 3); // tableta horizontal
    expect(Resp.cols(1280), 4); // escritorio
    expect(Resp.cols(3000), 4); // tope
  });
}
