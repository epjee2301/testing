<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['face_enrollment_photo', 'face_enrolled_at']);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->longText('face_enrollment_photo')->nullable();
            $table->timestamp('face_enrolled_at')->nullable();
        });
    }
};
