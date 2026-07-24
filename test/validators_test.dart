import 'package:flutter_test/flutter_test.dart';
import 'package:cuentas_claras/utils/validators.dart';

void main() {
  group('Validators.requiredField', () {
    test('null retorna error', () {
      expect(Validators.requiredField(null), isNotNull);
    });

    test('string vacío retorna error', () {
      expect(Validators.requiredField(''), isNotNull);
    });

    test('string con solo espacios retorna error', () {
      expect(Validators.requiredField('   '), isNotNull);
    });

    test('string con contenido retorna null', () {
      expect(Validators.requiredField('Hola'), isNull);
    });
  });

  group('Validators.email', () {
    test('null retorna error', () {
      expect(Validators.email(null), isNotNull);
    });

    test('string vacío retorna error', () {
      expect(Validators.email(''), isNotNull);
    });

    test('email válido retorna null', () {
      expect(Validators.email('test@example.com'), isNull);
    });

    test('email con subdominio retorna null', () {
      expect(Validators.email('user@mail.co.uk'), isNull);
    });

    test('email con puntos retorna null', () {
      expect(Validators.email('user.name@example.com'), isNull);
    });

    test('email sin @ retorna error', () {
      expect(Validators.email('testexample.com'), isNotNull);
    });

    test('email sin dominio retorna error', () {
      expect(Validators.email('test@'), isNotNull);
    });

    test('email con espacios retorna error', () {
      expect(Validators.email('test @example.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('null retorna error', () {
      expect(Validators.password(null), isNotNull);
    });

    test('string vacío retorna error', () {
      expect(Validators.password(''), isNotNull);
    });

    test('menos de 6 caracteres retorna error', () {
      expect(Validators.password('abc12'), isNotNull);
    });

    test('exactamente 6 caracteres retorna null', () {
      expect(Validators.password('abc123'), isNull);
    });

    test('más de 6 caracteres retorna null', () {
      expect(Validators.password('unaContraseñaSegura123'), isNull);
    });
  });

  group('Validators.amount', () {
    test('null retorna error', () {
      expect(Validators.amount(null), isNotNull);
    });

    test('string vacío retorna error', () {
      expect(Validators.amount(''), isNotNull);
    });

    test('texto no numérico retorna error', () {
      expect(Validators.amount('abc'), isNotNull);
    });

    test('cero retorna error', () {
      expect(Validators.amount('0'), isNotNull);
    });

    test('negativo retorna error', () {
      expect(Validators.amount('-10'), isNotNull);
    });

    test('número positivo retorna null', () {
      expect(Validators.amount('100'), isNull);
    });

    test('decimal positivo retorna null', () {
      expect(Validators.amount('99.99'), isNull);
    });
  });

  group('Validators.name', () {
    test('null retorna error', () {
      expect(Validators.name(null), isNotNull);
    });

    test('string vacío retorna error', () {
      expect(Validators.name(''), isNotNull);
    });

    test('menos de 3 caracteres retorna error', () {
      expect(Validators.name('Ab'), isNotNull);
    });

    test('exactamente 3 caracteres retorna null', () {
      expect(Validators.name('Ana'), isNull);
    });

    test('nombre completo retorna null', () {
      expect(Validators.name('Carlos Pérez'), isNull);
    });
  });
}