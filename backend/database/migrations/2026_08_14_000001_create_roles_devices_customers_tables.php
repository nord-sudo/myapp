<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique(); // admin, supervisor, prestamista
            $table->timestamps();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('role_id')->nullable()->constrained('roles')->nullOnDelete();
            $table->string('phone')->nullable();
            $table->enum('status', ['active', 'blocked'])->default('active');
            $table->string('avatar')->nullable();
        });

        Schema::create('devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('uuid')->unique();
            $table->string('model')->nullable();
            $table->string('os_version')->nullable();
            $table->string('last_ip')->nullable();
            $table->boolean('is_blocked')->default(false);
            $table->timestamp('last_connected_at')->nullable();
            $table->timestamps();
        });

        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('creator_id')->constrained('users')->onDelete('cascade');
            $table->string('first_name');
            $table->string('last_name');
            $table->string('identity_document')->unique();
            $table->string('phone');
            $table->string('whatsapp')->nullable();
            $table->string('email')->nullable();
            $table->text('address')->nullable();
            $table->string('city')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->string('marital_status')->nullable();
            $table->string('profession')->nullable();
            $table->decimal('salary', 12, 2)->nullable();
            $table->text('notes')->nullable();
            $table->longText('identity_document_front')->nullable();
            $table->longText('identity_document_back')->nullable();
            $table->enum('status', ['active', 'blocked', 'inactive'])->default('active');
            $table->timestamps();
        });

        Schema::create('customer_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('customers')->onDelete('cascade');
            $table->foreignId('uploaded_by')->constrained('users')->onDelete('cascade');
            $table->string('type'); // id_front, id_back, selfie, proof_of_address, proof_of_income, contract
            $table->string('file_path');
            $table->string('checksum')->nullable();
            $table->timestamps();
        });

        Schema::create('customer_references', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('customers')->onDelete('cascade');
            $table->string('name');
            $table->string('phone');
            $table->string('relationship')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('customer_references');
        Schema::dropIfExists('customer_documents');
        Schema::dropIfExists('customers');
        Schema::dropIfExists('devices');
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['role_id']);
            $table->dropColumn(['role_id', 'phone', 'status', 'avatar']);
        });
        Schema::dropIfExists('roles');
    }
};
