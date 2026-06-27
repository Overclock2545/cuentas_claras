class Validators {
  Validators._();

  static String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese su correo electrónico';
    }

    final emailRegex = RegExp(
      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Correo electrónico inválido';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese una contraseña';
    }

    if (value.length < 6) {
      return 'Debe tener al menos 6 caracteres';
    }

    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese un monto';
    }

    final number = double.tryParse(value);

    if (number == null) {
      return 'Monto inválido';
    }

    if (number <= 0) {
      return 'El monto debe ser mayor a 0';
    }

    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese un nombre';
    }

    if (value.trim().length < 3) {
      return 'Nombre demasiado corto';
    }

    return null;
  }
}