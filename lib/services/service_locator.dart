import 'package:cuentas_claras/services/auth_service.dart';

AuthService? _authService;

AuthService get authService => _authService ??= AuthService();
