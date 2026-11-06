<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_log_in_and_log_out(): void
    {
        $user = User::create([
            'name' => 'Test User',
            'email' => 'user@example.com',
            'password' => 'password',
            'role' => 'karyawan',
        ]);

        $loginResponse = $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'password',
        ]);

        $loginResponse
            ->assertOk()
            ->assertJsonPath('role', 'karyawan')
            ->assertJsonStructure(['token']);

        $token = $loginResponse->json('token');

        $this->withToken($token)
            ->postJson('/api/logout')
            ->assertOk()
            ->assertJson(['message' => 'Logout berhasil']);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_login_rejects_invalid_credentials(): void
    {
        $this->postJson('/api/login', [
            'email' => 'user@example.com',
            'password' => 'wrong-password',
        ])->assertUnauthorized();
    }

    public function test_admin_cannot_sign_in_to_the_mobile_api(): void
    {
        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'password' => 'password',
            'role' => 'admin',
        ]);

        $this->postJson('/api/login', [
            'email' => $admin->email,
            'password' => 'password',
        ])->assertForbidden()
            ->assertJsonPath('message', 'Akun admin masuk melalui web Laravel. Aplikasi mobile hanya untuk HRD dan karyawan.');
    }
}
