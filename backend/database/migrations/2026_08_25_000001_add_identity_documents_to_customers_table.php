<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('customers', function (Blueprint $table) {
            if (!Schema::hasColumn('customers', 'identity_document_front')) {
                $table->longText('identity_document_front')->nullable();
            }
            if (!Schema::hasColumn('customers', 'identity_document_back')) {
                $table->longText('identity_document_back')->nullable();
            }
        });
    }

    public function down()
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->dropColumn(['identity_document_front', 'identity_document_back']);
        });
    }
};
