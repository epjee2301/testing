<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::firstOrCreate(
            ['email' => 'admin@lookin.com'],
            [
                'name' => 'Admin LookIn',
                'password' => Hash::make('password123'),
                'role' => 'admin',
            ]
        );

        User::firstOrCreate(
            ['email' => 'hrd@lookin.com'],
            [
                'name' => 'HRD LookIn',
                'password' => Hash::make('password123'),
                'role' => 'hrd',
            ]
        );

        User::firstOrCreate(
            ['email' => 'karyawan@lookin.com'],
            [
                'name' => 'Karyawan LookIn',
                'password' => Hash::make('password123'),
                'role' => 'karyawan',
            ]
        );
    }
}
