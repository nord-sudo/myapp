<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FinancialPayment extends Model
{
    use HasFactory;

    protected $table = 'financial_payments';

    protected $fillable = [
        'uuid',
        'loan_id',
        'installment_id',
        'customer_id',
        'user_id',
        'idempotency_key',
        'receipt_number',
        'amount',
        'payment_method',
        'proof_image_path',
        'payment_date',
        'latitude',
        'longitude',
        'status',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'payment_date' => 'date',
        'latitude' => 'float',
        'longitude' => 'float',
    ];

    public function loan()
    {
        return $this->belongsTo(FinancialLoan::class, 'loan_id');
    }

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
