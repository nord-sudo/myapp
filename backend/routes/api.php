<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\LoanController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\CreditCheckController;

/*
|--------------------------------------------------------------------------
| API Routes - Prestamistas Pro (DOP / RD$)
|--------------------------------------------------------------------------
*/

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Public calculation & credit check endpoints
Route::post('/loans/calculate', [LoanController::class, 'calculate']);
Route::post('/credit-check', [CreditCheckController::class, 'check']);

// Dashboard metrics
Route::get('/dashboard/metrics', [DashboardController::class, 'metrics']);

// Customers CRUD
Route::apiResource('customers', CustomerController::class);

// Financial Loans & Payments
Route::get('loans/{id}/installments', [LoanController::class, 'installments']);
Route::get('loans/{id}/payments', [LoanController::class, 'payments']);
Route::get('loans/{id}/early-payoff', [LoanController::class, 'earlyPayoff']);
Route::patch('loans/{loanId}/installments/{installmentId}/overdue', [LoanController::class, 'markInstallmentOverdue']);
Route::apiResource('loans', LoanController::class);
Route::apiResource('payments', PaymentController::class);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    Route::post('/logout', [AuthController::class, 'logout']);
});