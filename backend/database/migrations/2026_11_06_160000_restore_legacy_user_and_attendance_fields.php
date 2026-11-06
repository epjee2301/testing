<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('employee_id')->nullable();
            $table->string('phone')->nullable();
            $table->string('division')->nullable();
            $table->string('position')->nullable();
            $table->text('address')->nullable();
            $table->string('gender')->nullable();
            $table->date('birth_date')->nullable();
            $table->date('joined_date')->nullable();
            $table->string('shift_time')->nullable();
            $table->string('branch')->nullable();
            $table->string('avatar')->nullable();
            $table->string('face_depan')->nullable();
            $table->string('face_samping_kiri')->nullable();
            $table->string('face_samping_kanan')->nullable();
            $table->string('face_menunduk')->nullable();
            $table->string('face_menengadah')->nullable();
        });

        Schema::table('presensis', function (Blueprint $table) {
            $table->string('status')->default('bekerja');
            $table->time('jam_mulai_istirahat')->nullable();
            $table->time('jam_selesai_istirahat')->nullable();
            $table->unsignedInteger('total_istirahat_detik')->default(0);
        });
    }

    public function down(): void
    {
        Schema::table('presensis', function (Blueprint $table) {
            $table->dropColumn([
                'status',
                'jam_mulai_istirahat',
                'jam_selesai_istirahat',
                'total_istirahat_detik',
            ]);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'employee_id',
                'phone',
                'division',
                'position',
                'address',
                'gender',
                'birth_date',
                'joined_date',
                'shift_time',
                'branch',
                'avatar',
                'face_depan',
                'face_samping_kiri',
                'face_samping_kanan',
                'face_menunduk',
                'face_menengadah',
            ]);
        });
    }
};
