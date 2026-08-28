<?php

namespace App\Services;

use App\Models\FinancialLoan;
use App\Models\FinancialPayment;
use App\Models\LoanInstallment;
use App\Models\CashRegister;
use App\Services\AuditService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Exception;

class PaymentService
{
    /**
     * Process an idempotent financial payment.
     * Allocates the payment to installments in FIFO order (oldest first).
     * Updates loan balance and status automatically.
     */
    public function processPayment(array $data, int $userId): FinancialPayment
    {
        // 1. Idempotency Check — prevent double payments
        $existing = FinancialPayment::where('idempotency_key', $data['idempotency_key'])->first();
        if ($existing) {
            return $existing;
        }

        return DB::transaction(function () use ($data, $userId) {
            $loan = FinancialLoan::where('id', $data['loan_id'])
                ->lockForUpdate()
                ->firstOrFail();

            if (!in_array($loan->status, ['active', 'overdue', 'disbursed'])) {
                throw new Exception('Este préstamo no acepta pagos (estado: ' . $loan->status . ').');
            }

            $amountToPay = round((float) $data['amount'], 2);
            if ($amountToPay <= 0) {
                throw new Exception('El monto del pago debe ser mayor a cero.');
            }

            // 2. Generate unique receipt number
            $receiptNumber = 'REC-' . date('Ymd') . '-' . strtoupper(Str::random(6));

            // 3. Create the payment record
            $payment = FinancialPayment::create([
                'uuid'            => (string) Str::uuid(),
                'loan_id'         => $loan->id,
                'customer_id'     => $loan->customer_id,
                'user_id'         => $userId,
                'idempotency_key' => $data['idempotency_key'],
                'receipt_number'  => $receiptNumber,
                'amount'          => $amountToPay,
                'payment_method'  => $data['payment_method'] ?? 'cash',
                'proof_image_path'=> $data['proof_image_path'] ?? null,
                'payment_date'    => $data['payment_date'] ?? date('Y-m-d'),
                'latitude'        => $data['latitude'] ?? null,
                'longitude'       => $data['longitude'] ?? null,
                'status'          => 'confirmed',
            ]);

            // 4. Allocate payment pool to installments (FIFO — oldest due first)
            $pool = $amountToPay;
            $installments = LoanInstallment::where('loan_id', $loan->id)
                ->whereIn('status', ['pending', 'partial', 'overdue'])
                ->orderBy('installment_number', 'asc')
                ->get();

            foreach ($installments as $inst) {
                if ($pool <= 0) break;

                $due = round($inst->total_amount - $inst->paid_amount, 2);
                if ($due <= 0) continue;

                if ($pool >= $due) {
                    $inst->paid_amount = $inst->total_amount;
                    $inst->status = 'paid';
                    $pool = round($pool - $due, 2);
                } else {
                    $inst->paid_amount = round($inst->paid_amount + $pool, 2);
                    $inst->status = 'partial';
                    $pool = 0;
                }
                $inst->save();
            }

            // 5. Update loan balance
            $loan->balance_remaining = max(0, round($loan->balance_remaining - $amountToPay, 2));

            // 6. Determine new loan status
            $pendingCount = LoanInstallment::where('loan_id', $loan->id)
                ->whereIn('status', ['pending', 'partial', 'overdue'])
                ->count();

            if ($loan->balance_remaining <= 0 || $pendingCount === 0) {
                $loan->status = 'paid';
            } elseif (LoanInstallment::where('loan_id', $loan->id)->where('status', 'overdue')->exists()) {
                $loan->status = 'overdue';
            } else {
                $loan->status = 'active';
            }

            $loan->save();

            // 7. Update open cash register if cash payment
            if (($data['payment_method'] ?? 'cash') === 'cash') {
                $cashReg = CashRegister::where('user_id', $userId)
                    ->where('status', 'open')
                    ->latest()
                    ->first();
                if ($cashReg) {
                    $cashReg->expected_balance += $amountToPay;
                    $cashReg->save();
                }
            }

            // 8. Audit
            AuditService::log('REGISTER_PAYMENT', $payment, null, $payment->toArray());

            return $payment;
        });
    }

    /**
     * Mark a specific installment as overdue and update the parent loan.
     */
    public function markInstallmentOverdue(int $loanId, int $installmentId): LoanInstallment
    {
        return DB::transaction(function () use ($loanId, $installmentId) {
            $inst = LoanInstallment::where('loan_id', $loanId)
                ->where('id', $installmentId)
                ->firstOrFail();

            $inst->status = 'overdue';
            $inst->save();

            FinancialLoan::where('id', $loanId)->update(['status' => 'overdue']);

            return $inst;
        });
    }
}
