<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('loan_products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->decimal('default_interest_rate', 5, 2);
            $table->enum('interest_type', ['fixed', 'declining_balance'])->default('fixed');
            $table->enum('default_frequency', ['daily', 'weekly', 'biweekly', 'monthly'])->default('daily');
            $table->decimal('penalty_rate', 5, 2)->default(0.00);
            $table->decimal('min_amount', 12, 2)->default(100.00);
            $table->decimal('max_amount', 12, 2)->default(1000000.00);
            $table->timestamps();
        });

        Schema::create('financial_loans', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('customer_id')->constrained('customers')->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade'); // lender/collector
            $table->foreignId('loan_product_id')->nullable()->constrained('loan_products')->nullOnDelete();
            $table->decimal('amount', 12, 2);
            $table->decimal('interest_rate', 5, 2);
            $table->integer('term_units');
            $table->enum('frequency', ['daily', 'weekly', 'biweekly', 'monthly'])->default('daily');
            $table->decimal('total_amount', 12, 2);
            $table->decimal('balance_remaining', 12, 2);
            $table->enum('status', ['draft', 'pending', 'approved', 'disbursed', 'active', 'overdue', 'paid', 'canceled', 'refinanced'])->default('active');
            $table->date('disbursed_at');
            $table->date('due_date');
            $table->timestamps();
        });

        Schema::create('loan_installments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('loan_id')->constrained('financial_loans')->onDelete('cascade');
            $table->integer('installment_number');
            $table->date('due_date');
            $table->decimal('principal_amount', 12, 2);
            $table->decimal('interest_amount', 12, 2);
            $table->decimal('penalty_amount', 12, 2)->default(0.00);
            $table->decimal('total_amount', 12, 2);
            $table->decimal('paid_amount', 12, 2)->default(0.00);
            $table->enum('status', ['pending', 'partial', 'paid', 'overdue'])->default('pending');
            $table->timestamps();
        });

        Schema::create('financial_payments', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('loan_id')->constrained('financial_loans')->onDelete('cascade');
            $table->foreignId('installment_id')->nullable()->constrained('loan_installments')->nullOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('idempotency_key')->unique();
            $table->string('receipt_number')->unique();
            $table->decimal('amount', 12, 2);
            $table->enum('payment_method', ['cash', 'transfer', 'card', 'other'])->default('cash');
            $table->string('proof_image_path')->nullable();
            $table->date('payment_date');
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->enum('status', ['confirmed', 'reversed', 'canceled'])->default('confirmed');
            $table->timestamps();
        });

        Schema::create('cash_registers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->decimal('opening_balance', 12, 2)->default(0.00);
            $table->decimal('closing_balance', 12, 2)->nullable();
            $table->decimal('expected_balance', 12, 2)->default(0.00);
            $table->enum('status', ['open', 'closed'])->default('open');
            $table->timestamp('opened_at');
            $table->timestamp('closed_at')->nullable();
            $table->text('discrepancy_notes')->nullable();
            $table->timestamps();
        });

        Schema::create('collection_visits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('customers')->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('reason'); // cobro, mora, verificacion, entrega
            $table->string('result');
            $table->text('comment')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->string('photo_path')->nullable();
            $table->timestamp('visited_at');
            $table->timestamps();
        });

        Schema::create('payment_promises', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('customers')->onDelete('cascade');
            $table->foreignId('loan_id')->constrained('financial_loans')->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->decimal('promised_amount', 12, 2);
            $table->date('promise_date');
            $table->enum('status', ['pending', 'fulfilled', 'unfulfilled', 'canceled'])->default('pending');
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        Schema::create('commissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('loan_id')->nullable()->constrained('financial_loans')->nullOnDelete();
            $table->foreignId('payment_id')->nullable()->constrained('financial_payments')->nullOnDelete();
            $table->decimal('amount', 12, 2);
            $table->enum('status', ['pending', 'paid'])->default('pending');
            $table->timestamp('calculated_at');
            $table->timestamps();
        });

        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action');
            $table->string('model')->nullable();
            $table->unsignedBigInteger('model_id')->nullable();
            $table->json('old_values')->nullable();
            $table->json('new_values')->nullable();
            $table->string('ip_address')->nullable();
            $table->string('device_uuid')->nullable();
            $table->timestamps();
        });

        Schema::create('sync_queues', function (Blueprint $table) {
            $table->id();
            $table->string('device_uuid');
            $table->string('local_uuid');
            $table->string('entity_type');
            $table->string('action');
            $table->json('payload');
            $table->enum('status', ['pending', 'processed', 'failed'])->default('pending');
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('sync_queues');
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('commissions');
        Schema::dropIfExists('payment_promises');
        Schema::dropIfExists('collection_visits');
        Schema::dropIfExists('cash_registers');
        Schema::dropIfExists('financial_payments');
        Schema::dropIfExists('loan_installments');
        Schema::dropIfExists('financial_loans');
        Schema::dropIfExists('loan_products');
    }
};
