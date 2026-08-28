import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/use_cases/register_payment_use_case.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final RegisterPaymentUseCase registerPayment;

  PaymentBloc({required this.registerPayment}) : super(PaymentInitial()) {
    on<RegisterPayment>(_onRegisterPayment);
  }

  Future<void> _onRegisterPayment(RegisterPayment event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      final payment = await registerPayment(event.loanId, event.amount, event.type);
      emit(PaymentSuccess(payment));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}
