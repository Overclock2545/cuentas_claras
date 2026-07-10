import 'package:flutter/material.dart';

import '../../views/auth/login_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/home/home_screen.dart';
import '../../views/event/create_event_screen.dart';
import '../../views/splash/splash_screen.dart';
import '../../views/event/event_detail_screen.dart';
import '../../views/expense/add_expense_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const String eventDetail = '/event-detail';
  static const expenses = '/expenses';
  static const summary = '/summary';
  static const settle = '/settle';
  static const profile = '/profile';
  static const String createEvent = '/create-event';
  static const String addExpense = '/add-expense';
  

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
//        forgotPassword: (_) => const ForgotPasswordScreen(),
        home: (_) => const HomeScreen(),
      AppRoutes.eventDetail: (context) => const EventDetailScreen(),
//        expenses: (_) => const ExpensesScreen(),
//        summary: (_) => const SummaryScreen(),
//        settle: (_) => const SettleScreen(),
//        profile: (_) => const ProfileScreen(),
        createEvent: (context) => const CreateEventScreen(),
        splash: (_) => const SplashScreen(),
        addExpense: (context) => const AddExpenseScreen(),
      };
}