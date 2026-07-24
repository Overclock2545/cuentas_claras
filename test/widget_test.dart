import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras/main.dart';

void main() {
  testWidgets('app builds without crashing', (WidgetTester tester) async {
    // Solo verificamos que buildApp() no lance excepciones
    // No podemos probar el splash completo porque requiere Firebase
    expect(buildApp, returnsNormally);
  });
}