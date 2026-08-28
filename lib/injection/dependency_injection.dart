import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

// Auth
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/use_cases/login_use_case.dart';
import '../features/auth/domain/use_cases/logout_use_case.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

// Clients
import '../features/clients/data/repositories/client_repository_impl.dart';
import '../features/clients/domain/repositories/client_repository.dart';
import '../features/clients/domain/use_cases/add_client_use_case.dart';
import '../features/clients/domain/use_cases/get_clients_use_case.dart';
import '../features/clients/presentation/bloc/client_bloc.dart';

// Loans
import '../features/loans/data/repositories/loan_repository_impl.dart';
import '../features/loans/domain/repositories/loan_repository.dart';
import '../features/loans/domain/use_cases/create_loan_use_case.dart';
import '../features/loans/domain/use_cases/get_loans_use_case.dart';
import '../features/loans/presentation/bloc/loan_bloc.dart';

// Payments
import '../features/payments/data/repositories/payment_repository_impl.dart';
import '../features/payments/domain/repositories/payment_repository.dart';
import '../features/payments/domain/use_cases/register_payment_use_case.dart';
import '../features/payments/presentation/bloc/payment_bloc.dart';

// Settings
import '../features/settings/presentation/bloc/settings_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<ClientRepository>(() => ClientRepositoryImpl());
  sl.registerLazySingleton<LoanRepository>(() => LoanRepositoryImpl());
  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl());

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetClientsUseCase(sl()));
  sl.registerLazySingleton(() => AddClientUseCase(sl()));
  sl.registerLazySingleton(() => GetLoansUseCase(sl()));
  sl.registerLazySingleton(() => CreateLoanUseCase(sl()));
  sl.registerLazySingleton(() => RegisterPaymentUseCase(sl()));

  // BLoCs
  sl.registerFactory(() => AuthBloc(
        authRepository: sl(),
        loginUseCase: sl(),
        logoutUseCase: sl(),
      ));
  sl.registerFactory(() => ClientBloc(
        getClients: sl(),
        addClient: sl(),
      ));
  sl.registerFactory(() => LoanBloc(
        getLoans: sl(),
        createLoan: sl(),
      ));
  sl.registerFactory(() => PaymentBloc(
        registerPayment: sl(),
      ));
  sl.registerFactory(() => SettingsCubit());
}

List<BlocProvider> get providers => [
      BlocProvider<AuthBloc>(create: (context) => sl<AuthBloc>()),
      BlocProvider<ClientBloc>(create: (context) => sl<ClientBloc>()),
      BlocProvider<LoanBloc>(create: (context) => sl<LoanBloc>()),
      BlocProvider<PaymentBloc>(create: (context) => sl<PaymentBloc>()),
      BlocProvider<SettingsCubit>(create: (context) => sl<SettingsCubit>()),
    ];
