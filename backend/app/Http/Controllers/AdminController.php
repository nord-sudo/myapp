<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Models\FinancialLoan;
use App\Models\FinancialPayment;
use App\Models\LoanInstallment;
use App\Models\AuditLog;
use App\Models\User;
use App\Services\FinancialEngineService;
use App\Services\PaymentService;
use App\Services\AuditService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Carbon\Carbon;

class AdminController extends Controller
{
    public function dashboard()
    {
        $today = Carbon::today()->format('Y-m-d');
        $startOfMonth = Carbon::now()->startOfMonth()->format('Y-m-d');

        $collectedToday = FinancialPayment::whereDate('payment_date', $today)->where('status', 'confirmed')->sum('amount');
        $collectedThisMonth = FinancialPayment::whereDate('payment_date', '>=', $startOfMonth)->where('status', 'confirmed')->sum('amount');
        $pendingToday = LoanInstallment::whereDate('due_date', $today)->whereIn('status', ['pending', 'partial'])->sum(DB::raw('total_amount - paid_amount'));
        $totalPortfolio = FinancialLoan::whereIn('status', ['active', 'overdue'])->sum('balance_remaining');
        $totalDisbursed = FinancialLoan::sum('amount');
        $overdueAmount = LoanInstallment::where('due_date', '<', $today)->whereIn('status', ['pending', 'partial'])->sum(DB::raw('total_amount - paid_amount'));

        $totalCustomers = Customer::count();
        $totalLoans = FinancialLoan::count();
        $activeLoansCount = FinancialLoan::where('status', 'active')->count();
        $overdueLoansCount = FinancialLoan::where('status', 'overdue')->count();
        $paidLoansCount = FinancialLoan::where('status', 'paid')->count();
        $totalPayments = FinancialPayment::count();
        $totalLenders = User::where('role_id', '!=', 1)->orWhereNull('role_id')->count();
        $pendingRequestsCount = 3; // Demo pending requests count

        $recentPayments = FinancialPayment::with(['customer', 'loan'])->latest()->take(7)->get();
        $recentLoans = FinancialLoan::with(['customer'])->latest()->take(5)->get();

        // Monthly chart data (last 6 months)
        $chartLabels = [];
        $chartCollected = [];
        $chartDisbursed = [];

        for ($i = 5; $i >= 0; $i--) {
            $month = Carbon::now()->subMonths($i);
            $chartLabels[] = $month->translatedFormat('F');
            $mStart = $month->copy()->startOfMonth()->format('Y-m-d');
            $mEnd = $month->copy()->endOfMonth()->format('Y-m-d');

            $chartCollected[] = (float) FinancialPayment::whereBetween('payment_date', [$mStart, $mEnd])->where('status', 'confirmed')->sum('amount');
            $chartDisbursed[] = (float) FinancialLoan::whereBetween('disbursed_at', [$mStart, $mEnd])->sum('amount');
        }

        // Recent activity feed
        $recentActivities = [
            ['user' => 'Carlos (Prestamista)', 'action' => 'Registró cobro de RD$ 1,500 en efectivo', 'time' => 'Hace 5 min', 'type' => 'payment'],
            ['user' => 'Sistema', 'action' => 'Se creó automáticamente el préstamo #LOAN-1025', 'time' => 'Hace 18 min', 'type' => 'loan'],
            ['user' => 'Sistema', 'action' => 'Juan Pérez entró en estado de Mora automática', 'time' => 'Hace 1 hora', 'type' => 'mora'],
            ['user' => 'María (Prestamista)', 'action' => 'Registró nuevo cliente con fotos de Cédula (Frente y Reverso)', 'time' => 'Hace 2 horas', 'type' => 'customer'],
            ['user' => 'Administrador', 'action' => 'Aprobó solicitud de aumento de límite a RD$ 50,000', 'time' => 'Hace 3 horas', 'type' => 'approval'],
        ];

        return view('admin.dashboard', compact(
            'collectedToday', 'collectedThisMonth', 'pendingToday', 'totalPortfolio', 'totalDisbursed', 'overdueAmount',
            'totalCustomers', 'totalLoans', 'activeLoansCount', 'overdueLoansCount', 'paidLoansCount',
            'totalPayments', 'totalLenders', 'pendingRequestsCount',
            'recentPayments', 'recentLoans', 'recentActivities',
            'chartLabels', 'chartCollected', 'chartDisbursed'
        ));
    }

    public function customers(Request $request)
    {
        $query = Customer::withCount(['loans' => function ($q) {
            $q->whereIn('status', ['active', 'overdue']);
        }]);

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                  ->orWhere('last_name', 'like', "%{$search}%")
                  ->orWhere('identity_document', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        $customers = $query->latest()->paginate(15);
        $lenders = User::orderBy('name')->get();

        return view('admin.customers', compact('customers', 'lenders'));
    }

    public function showCustomer($id)
    {
        $customer = Customer::with(['loans.installments', 'payments'])->findOrFail($id);
        return view('admin.customer_expediente', compact('customer'));
    }

    public function updateCustomerDocuments(Request $request, $id)
    {
        $customer = Customer::findOrFail($id);

        if ($request->hasFile('identity_document_front')) {
            $frontPath = $request->file('identity_document_front')->store('customers', 'public');
            $customer->identity_document_front = $frontPath;
        }

        if ($request->hasFile('identity_document_back')) {
            $backPath = $request->file('identity_document_back')->store('customers', 'public');
            $customer->identity_document_back = $backPath;
        }

        $customer->save();

        return redirect()->back()->with('success', '¡Fotos de Cédula actualizadas correctamente!');
    }

    public function storeCustomer(Request $request)
    {
        $request->validate([
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'identity_document' => 'required|string|max:20',
            'phone' => 'required|string|max:20',
            'address' => 'required|string',
            'city' => 'nullable|string|max:100',
        ]);

        $customer = Customer::updateOrCreate(
            ['identity_document' => $request->identity_document],
            [
                'creator_id' => auth()->id() ?? 1,
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'identity_document' => $request->identity_document,
                'phone' => $request->phone,
                'whatsapp' => $request->whatsapp ?? $request->phone,
                'address' => $request->address,
                'city' => $request->city ?? 'Santo Domingo',
                'salary' => $request->salary ?? 0.00,
                'status' => 'active',
            ]
        );

        AuditService::log('CREATE_CUSTOMER_WEB', $customer, null, $customer->toArray());

        return redirect()->route('admin.customers')->with('success', '¡Cliente registrado correctamente!');
    }

    public function lenders()
    {
        $lenders = User::latest()->paginate(15);
        return view('admin.lenders', compact('lenders'));
    }

    public function storeLender(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
        ]);

        $lender = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone ?? '809-555-0000',
            'status' => 'active',
        ]);

        AuditService::log('CREATE_LENDER_WEB', $lender, null, $lender->toArray());

        return redirect()->route('admin.lenders')->with('success', '¡Prestamista registrado exitosamente!');
    }

    public function loans(Request $request)
    {
        $query = FinancialLoan::with(['customer', 'installments']);

        if ($request->has('status') && !empty($request->status)) {
            $query->where('status', $request->status);
        }

        $loans = $query->latest()->paginate(15);
        $customersList = Customer::orderBy('first_name')->get();

        return view('admin.loans', compact('loans', 'customersList'));
    }

    public function storeLoan(Request $request, FinancialEngineService $engine)
    {
        $request->validate([
            'customer_id' => 'required|exists:customers,id',
            'amount' => 'required|numeric|min:100',
            'interest_rate' => 'required|numeric|min:1',
            'term_units' => 'required|integer|min:1',
            'frequency' => 'required|in:daily,weekly,biweekly,monthly',
            'start_date' => 'required|date',
        ]);

        $calculation = $engine->generateAmortizationSchedule(
            (float) $request->amount,
            (float) $request->interest_rate,
            (int) $request->term_units,
            $request->frequency,
            $request->start_date
        );

        $loan = FinancialLoan::create([
            'uuid' => (string) Str::uuid(),
            'loan_number' => 'LOAN-' . date('Ymd') . '-' . rand(100, 999),
            'customer_id' => $request->customer_id,
            'amount' => $calculation['amount'],
            'interest_rate' => $calculation['interest_rate'],
            'total_interest' => $calculation['total_interest'],
            'total_amount' => $calculation['total_amount'],
            'balance_remaining' => $calculation['total_amount'],
            'term_units' => $calculation['term_units'],
            'frequency' => $calculation['frequency'],
            'start_date' => $request->start_date,
            'status' => 'active',
        ]);

        foreach ($calculation['schedule'] as $item) {
            LoanInstallment::create([
                'loan_id' => $loan->id,
                'installment_number' => $item['installment_number'],
                'due_date' => $item['due_date'],
                'principal_amount' => $item['principal_amount'],
                'interest_amount' => $item['interest_amount'],
                'total_amount' => $item['total_amount'],
                'paid_amount' => 0.00,
                'status' => 'pending',
            ]);
        }

        AuditService::log('CREATE_LOAN_WEB', $loan, null, $loan->toArray());

        return redirect()->route('admin.loans')->with('success', '¡Préstamo desembolsado y cuotas creadas correctamente!');
    }

    public function payments(Request $request)
    {
        $query = FinancialPayment::with(['customer', 'loan']);

        if ($request->has('method') && !empty($request->method)) {
            $query->where('payment_method', $request->method);
        }

        $payments = $query->latest()->paginate(15);
        $activeLoansList = FinancialLoan::with('customer')->whereIn('status', ['active', 'overdue'])->get();

        return view('admin.payments', compact('payments', 'activeLoansList'));
    }

    public function storePayment(Request $request, PaymentService $paymentService)
    {
        $request->validate([
            'loan_id' => 'required|exists:financial_loans,id',
            'amount' => 'required|numeric|min:1',
            'payment_method' => 'required|in:cash,transfer',
            'proof_image' => 'nullable|image|max:4096',
        ]);

        $proofPath = null;
        if ($request->hasFile('proof_image')) {
            $proofPath = $request->file('proof_image')->store('proofs', 'public');
        }

        $payment = $paymentService->processPayment([
            'loan_id' => $request->loan_id,
            'amount' => $request->amount,
            'payment_method' => $request->payment_method,
            'proof_image_path' => $proofPath,
            'idempotency_key' => (string) Str::uuid(),
            'payment_date' => date('Y-m-d'),
        ], 1);

        return redirect()->route('admin.payments')->with('success', '¡Cobro de RD$ ' . number_format($payment->amount, 2) . ' registrado con éxito!');
    }

    public function audit()
    {
        $logs = AuditLog::latest()->paginate(20);
        return view('admin.audit', compact('logs'));
    }

    public function settings()
    {
        return view('admin.settings');
    }
}
