<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminController;

/*
|--------------------------------------------------------------------------
| Web Routes - Panel Web Administrativo Prestamistas Pro (DOP / RD$)
|--------------------------------------------------------------------------
*/

Route::get('/', [AdminController::class, 'dashboard'])->name('admin.dashboard');

Route::get('/customers', [AdminController::class, 'customers'])->name('admin.customers');
Route::post('/customers', [AdminController::class, 'storeCustomer'])->name('admin.customers.store');
Route::get('/customers/{id}', [AdminController::class, 'showCustomer'])->name('admin.customers.show');
Route::post('/customers/{id}/documents', [AdminController::class, 'updateCustomerDocuments'])->name('admin.customers.documents');

Route::get('/lenders', [AdminController::class, 'lenders'])->name('admin.lenders');
Route::post('/lenders', [AdminController::class, 'storeLender'])->name('admin.lenders.store');

Route::get('/loans', [AdminController::class, 'loans'])->name('admin.loans');
Route::post('/loans', [AdminController::class, 'storeLoan'])->name('admin.loans.store');

Route::get('/payments', [AdminController::class, 'payments'])->name('admin.payments');
Route::post('/payments', [AdminController::class, 'storePayment'])->name('admin.payments.store');

Route::get('/audit', [AdminController::class, 'audit'])->name('admin.audit');
Route::get('/settings', [AdminController::class, 'settings'])->name('admin.settings');
