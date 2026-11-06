<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('presensis', function (Blueprint $table) {
            $table->string('foto_masuk')->nullable()->change();
            $table->string('foto_pulang')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('presensis', function (Blueprint $table) {
            $table->string('foto_masuk')->nullable(false)->change();
        });
    }
};
