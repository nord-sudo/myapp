<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FinancialLoan extends Model
{
    use HasFactory;

    protected $table = 'financial_loans';

    protected $fillable = [
        'uuid',
        'customer_id',
        'user_id',
        'loan_product_id',
        'amount',
        'interest_rate',
        'term_units',
        'frequency',
        'total_amount',
        'balance_remaining',
        'status',
        'disbursed_at',
        'due_date',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'interest_rate' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'balance_remaining' => 'decimal:2',
        'disbursed_at' => 'date',
        'due_date' => 'date',
    ];

    protected $appends = ['start_date', 'next_payment_date'];

    public function getStartDateAttribute()
    {
        return $this->disbursed_at ? $this->disbursed_at->format('Y-m-d') : null;
    }

    public function getNextPaymentDateAttribute()
    {
        $nextInstallment = $this->installments()
            ->whereIn('status', ['pending', 'partial', 'overdue'])
            ->orderBy('due_date', 'asc')
            ->first();

        return $nextInstallment ? $nextInstallment->due_date->format('Y-m-d') : ($this->due_date ? $this->due_date->format('Y-m-d') : null);
    }

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function installments()
    {
        return $this->hasMany(LoanInstallment::class, 'loan_id')->orderBy('installment_number');
    }

    public function payments()
    {
        return $this->hasMany(FinancialPayment::class, 'loan_id');
    }
}
