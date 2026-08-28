<?php

namespace App\Http\Controllers;

use App\Models\FinancialLoan;
use App\Models\LoanInstallment;
use App\Services\FinancialEngineService;
use App\Services\AuditService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Validator;

class LoanController extends Controller
{
    protected $financialEngine;

    public function __construct(FinancialEngineService $financialEngine)
    {
        $this->financialEngine = $financialEngine;
    }

    public function index(Request $request)
    {
        $this->evaluateOverdueStatus();

        $query = FinancialLoan::with('customer');

        $user = auth()->user();
        $isAdmin = $user && ($user->role_id == 1 || str_contains(strtolower($user->email ?? ''), 'admin'));
        if (!$isAdmin && auth()->id()) {
            $query->where('user_id', auth()->id());
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('customer_id')) {
            $query->where('customer_id', $request->customer_id);
        }

        return response()->json($query->latest()->paginate(20));
    }


    public function calculate(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount'        => 'required|numeric|min:100',
            'interest_rate' => 'required|numeric|min:0|max:100',
            'term_units'    => 'required|integer|min:1',
            'frequency'     => 'required|in:daily,weekly,biweekly,monthly',
            'start_date'    => 'required|date_format:Y-m-d',
            'interest_type' => 'nullable|in:fixed,declining_balance',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $schedule = $this->financialEngine->generateAmortizationSchedule(
            (float) $request->amount,
            (float) $request->interest_rate,
            (int) $request->term_units,
            $request->frequency,
            $request->start_date,
            $request->input('interest_type', 'fixed')
        );

        return response()->json($schedule);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customer_id'   => 'required|exists:customers,id',
            'amount'        => 'required|numeric|min:100',
            'interest_rate' => 'required|numeric|min:0|max:100',
            'term_units'    => 'required|integer|min:1',
            'frequency'     => 'required|in:daily,weekly,biweekly,monthly',
            'start_date'    => 'required|date_format:Y-m-d',
            'interest_type' => 'nullable|in:fixed,declining_balance',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $calculation = $this->financialEngine->generateAmortizationSchedule(
            (float) $request->amount,
            (float) $request->interest_rate,
            (int) $request->term_units,
            $request->frequency,
            $request->start_date,
            $request->input('interest_type', 'fixed')
        );

        $loan = DB::transaction(function () use ($request, $calculation) {
            $lastInstallmentDate = end($calculation['schedule'])['due_date'];

            $loan = FinancialLoan::create([
                'uuid'              => (string) Str::uuid(),
                'customer_id'       => $request->customer_id,
                'user_id'           => auth()->id() ?? 1,
                'amount'            => $calculation['amount'],
                'interest_rate'     => $calculation['interest_rate'],
                'term_units'        => $calculation['term_units'],
                'frequency'         => $calculation['frequency'],
                'total_amount'      => $calculation['total_amount'],
                'balance_remaining' => $calculation['total_amount'],
                'status'            => 'active',
                'disbursed_at'      => $request->start_date,
                'due_date'          => $lastInstallmentDate,
            ]);

            foreach ($calculation['schedule'] as $item) {
                LoanInstallment::create([
                    'loan_id'            => $loan->id,
                    'installment_number' => $item['installment_number'],
                    'due_date'           => $item['due_date'],
                    'principal_amount'   => $item['principal_amount'],
                    'interest_amount'    => $item['interest_amount'],
                    'penalty_amount'     => $item['penalty_amount'],
                    'total_amount'       => $item['total_amount'],
                    'paid_amount'        => 0.00,
                    'status'             => 'pending',
                ]);
            }

            AuditService::log('CREATE_LOAN', $loan, null, $loan->toArray());

            return $loan;
        });

        return response()->json($loan->load('installments', 'customer'), 201);
    }

    public function show($id)
    {
        $this->evaluateOverdueStatus($id);

        $loan = FinancialLoan::with(['customer', 'installments', 'payments'])->findOrFail($id);

        // Append computed customer_name for mobile app convenience
        if ($loan->customer) {
            $loan->customer_name = $loan->customer->first_name . ' ' . $loan->customer->last_name;
            $loan->customer_phone = $loan->customer->phone;
            $loan->customer_cedula = $loan->customer->identity_document;
        }

        return response()->json($loan);
    }

    /**
     * GET /api/loans/{id}/installments
     * Return all installments for a loan ordered by installment_number.
     */
    public function installments($id)
    {
        $this->evaluateOverdueStatus($id);

        $loan = FinancialLoan::findOrFail($id);
        $installments = LoanInstallment::where('loan_id', $loan->id)
            ->orderBy('installment_number', 'asc')
            ->get();

        return response()->json($installments);
    }

    /**
     * GET /api/loans/{id}/early-payoff
     * Calculate early payoff / settlement amount for a loan.
     */
    public function earlyPayoff($id, Request $request)
    {
        $loan = FinancialLoan::findOrFail($id);
        $discountRate = (float) $request->input('discount_rate', 5.0);

        $calculation = $this->financialEngine->calculateEarlyPayoff(
            (float) $loan->balance_remaining,
            (float) $loan->amount,
            (float) $loan->total_amount,
            $discountRate
        );

        return response()->json($calculation);
    }

    /**
     * GET /api/loans/{id}/payments
     * Return all payments made on a loan ordered by newest first.
     */
    public function payments($id)
    {
        $loan = FinancialLoan::findOrFail($id);

        $payments = \App\Models\FinancialPayment::where('loan_id', $loan->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($payments);
    }

    /**
     * PATCH /api/loans/{loanId}/installments/{installmentId}/overdue
     * Mark a specific installment as overdue and update loan status.
     */
    public function markInstallmentOverdue($loanId, $installmentId)
    {
        $installment = LoanInstallment::where('loan_id', $loanId)
            ->where('id', $installmentId)
            ->firstOrFail();

        $installment->status = 'overdue';
        $installment->save();

        FinancialLoan::where('id', $loanId)->update(['status' => 'overdue']);

        return response()->json(['message' => 'Cuota marcada como mora correctamente', 'installment' => $installment]);
    }

    /**
     * Automatically evaluate past-due installments and mark loan status as overdue ("mora").
     */
    protected function evaluateOverdueStatus(?int $loanId = null): void
    {
        $today = date('Y-m-d');

        // Mark installments past due date as overdue
        $instQuery = LoanInstallment::where('due_date', '<', $today)
            ->whereIn('status', ['pending', 'partial']);

        if ($loanId) {
            $instQuery->where('loan_id', $loanId);
        }

        $overdueInstallments = $instQuery->get();

        foreach ($overdueInstallments as $inst) {
            $inst->status = 'overdue';

            // Compute late penalty (0.5% per day overdue)
            $penalty = $this->financialEngine->calculateLatePenalty($inst->toArray(), 0.5);
            $inst->penalty_amount = $penalty['penalty_amount'];
            $inst->save();

            // Mark parent loan as overdue
            FinancialLoan::where('id', $inst->loan_id)
                ->whereNotIn('status', ['paid', 'canceled'])
                ->update(['status' => 'overdue']);
        }
    }
}