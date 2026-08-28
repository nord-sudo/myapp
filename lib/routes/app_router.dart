import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/clients/presentation/screens/client_detail_screen.dart';
import '../features/clients/presentation/screens/client_form_screen.dart';
import '../features/clients/presentation/screens/clients_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/loans/presentation/screens/loan_detail_screen.dart';
import '../features/loans/presentation/screens/loan_form_screen.dart';
import '../features/loans/presentation/screens/loans_screen.dart';
import '../features/payments/presentation/screens/payment_screen.dart';
import '../features/payments/presentation/screens/receipt_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/clients',
      builder: (context, state) => const ClientsScreen(),
    ),
    GoRoute(
      path: '/clients/new',
      builder: (context, state) => const ClientFormScreen(),
    ),
    GoRoute(
      path: '/clients/:id',
      builder: (context, state) => ClientDetailScreen(
        clientId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/loans',
      builder: (context, state) => LoansScreen(
        initialStatus: state.uri.queryParameters['status'],
      ),
    ),
    GoRoute(
      path: '/loans/new',
      builder: (context, state) {
        final cidStr = state.uri.queryParameters['customerId'];
        final int? cid = cidStr != null ? int.tryParse(cidStr) : null;
        return LoanFormScreen(preselectedCustomerId: cid);
      },
    ),
    GoRoute(
      path: '/loans/:id',
      builder: (context, state) => LoanDetailScreen(
        loanId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) => PaymentScreen(
        loanId: state.uri.queryParameters['loanId'],
        clientId: state.uri.queryParameters['clientId'],
        initialAmount: state.uri.queryParameters['amount'],
      ),
    ),
    GoRoute(
      path: '/receipt',
      builder: (context, state) {
        final data = state.extra is Map<String, dynamic>
            ? state.extra as Map<String, dynamic>
            : <String, dynamic>{};
        return ReceiptScreen(receiptData: data);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
