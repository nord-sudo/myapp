<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    use HasFactory;

    protected $fillable = [
        'creator_id',
        'first_name',
        'last_name',
        'identity_document', // Cédula Dominicana
        'identity_document_front',
        'identity_document_back',
        'phone',
        'whatsapp',
        'email',
        'address',
        'city',
        'latitude',
        'longitude',
        'marital_status',
        'profession',
        'salary',
        'notes',
        'status',
    ];

    protected $casts = [
        'salary' => 'decimal:2',
        'latitude' => 'float',
        'longitude' => 'float',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'creator_id');
    }

    public function documents()
    {
        return $this->hasMany(CustomerDocument::class);
    }

    public function references()
    {
        return $this->hasMany(CustomerReference::class);
    }

    public function loans()
    {
        return $this->hasMany(FinancialLoan::class);
    }

    public function payments()
    {
        return $this->hasMany(FinancialPayment::class);
    }

    public function visits()
    {
        return $this->hasMany(CollectionVisit::class);
    }

    public function promises()
    {
        return $this->hasMany(PaymentPromise::class);
    }
}
