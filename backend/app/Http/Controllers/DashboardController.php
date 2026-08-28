<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Models\FinancialLoan;
use App\Models\FinancialPayment;
use App\Models\LoanInstallment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function metrics(Request $request)
    {
        $today = Carbon::today()->format('Y-m-d');
        $user = auth('sanctum')->user() ?? auth()->user();
        $userId = $user ? $user->id : null;
        $isAdmin = $user && ($user->role_id == 1 || str_contains(strtolower($user->email ?? ''), 'admin'));
        $targetUserId = $userId ?? 0;

        // 1. Cobrado Hoy (RD$)
        $paymentsQuery = FinancialPayment::whereDate('payment_date', $today)->where('status', 'confirmed');
        if (!$isAdmin) {
            $paymentsQuery->where('user_id', $targetUserId);
        }
        $collectedToday = $paymentsQuery->sum('amount');

        // 2. Pendiente por cobro hoy (RD$)
        $installmentsQuery = LoanInstallment::whereDate('due_date', $today)->whereIn('status', ['pending', 'partial']);
        if (!$isAdmin) {
            $installmentsQuery->whereHas('loan', function($q) use ($targetUserId) {
                $q->where('user_id', $targetUserId);
            });
        }
        $pendingToday = $installmentsQuery->sum(DB::raw('total_amount - paid_amount'));

        // 3. Resumen de Cartera (RD$)
        $loansQuery = FinancialLoan::whereIn('status', ['active', 'overdue']);
        if (!$isAdmin) {
            $loansQuery->where('user_id', $targetUserId);
        }
        $totalPortfolioBalance = (clone $loansQuery)->sum('balance_remaining');
        $activeLoansCount = (clone $loansQuery)->count();

        $customersQuery = Customer::where('status', 'active');
        if (!$isAdmin) {
            $customersQuery->where('creator_id', $targetUserId);
        }
        $activeCustomersCount = $customersQuery->count();

        // 4. Morosidad
        $overdueInstallmentsQuery = LoanInstallment::where('due_date', '<', $today)->whereIn('status', ['pending', 'partial']);
        if (!$isAdmin) {
            $overdueInstallmentsQuery->whereHas('loan', function($q) use ($targetUserId) {
                $q->where('user_id', $targetUserId);
            });
        }
        $overdueAmount = $overdueInstallmentsQuery->sum(DB::raw('total_amount - paid_amount'));

        $overdueCustQuery = Customer::whereHas('loans.installments', function ($q) use ($today) {
            $q->where('due_date', '<', $today)->whereIn('status', ['pending', 'partial']);
        });
        if (!$isAdmin) {
            $overdueCustQuery->where('creator_id', $targetUserId);
        }
        $overdueCustomersCount = $overdueCustQuery->count();

        // 5. Cobros Recientes
        $recentPaymentsQuery = FinancialPayment::with(['customer', 'loan'])->latest();
        if (!$isAdmin) {
            $recentPaymentsQuery->where('user_id', $targetUserId);
        }
        $recentPayments = $recentPaymentsQuery->take(5)->get();


        return response()->json([
            'currency' => 'DOP',
            'currency_symbol' => 'RD$',
            'collected_today' => round($collectedToday, 2),
            'pending_today' => round($pendingToday, 2),
            'total_portfolio_balance' => round($totalPortfolioBalance, 2),
            'active_loans_count' => $activeLoansCount,
            'active_customers_count' => $activeCustomersCount,
            'overdue_amount' => round($overdueAmount, 2),
            'overdue_customers_count' => $overdueCustomersCount,
            'recent_payments' => $recentPayments,
        ]);
    }

}
