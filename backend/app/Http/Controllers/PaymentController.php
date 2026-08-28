<?php

namespace App\Http\Controllers;

use App\Services\PaymentService;
use App\Models\FinancialPayment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class PaymentController extends Controller
{
    protected $paymentService;

    public function __construct(PaymentService $paymentService)
    {
        $this->paymentService = $paymentService;
    }

    public function index(Request $request)
    {
        $query = FinancialPayment::with(['customer', 'loan']);

        $user = auth()->user();
        $isAdmin = $user && ($user->role_id == 1 || str_contains(strtolower($user->email ?? ''), 'admin'));
        if (!$isAdmin && auth()->id()) {
            $query->where('user_id', auth()->id());
        }

        if ($request->has('loan_id')) {
            $query->where('loan_id', $request->loan_id);
        }

        if ($request->has('customer_id')) {
            $query->where('customer_id', $request->customer_id);
        }

        return response()->json($query->latest()->paginate(20));
    }


    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'loan_id' => 'required|exists:financial_loans,id',
            'amount' => 'required|numeric|min:0.01',
            'idempotency_key' => 'required|string|max:255',
            'payment_method' => 'required|in:cash,transfer,card,other',
            'payment_date' => 'nullable|date_format:Y-m-d',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $userId = auth()->id() ?? 1;
            $payment = $this->paymentService->processPayment($validator->validated(), $userId);
            return response()->json($payment->load(['customer', 'loan']), 201);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 400);
        }
    }

    public function show($id)
    {
        $payment = FinancialPayment::with(['customer', 'loan.installments'])->findOrFail($id);
        return response()->json($payment);
    }
}