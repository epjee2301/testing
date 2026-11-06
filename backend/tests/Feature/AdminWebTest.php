<?php

namespace Tests\Feature;

use App\Models\EmployeeRequest;
use App\Models\Presensi;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminWebTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_web_login_and_dashboard_are_available_only_to_admin(): void
    {
        $admin = $this->makeUser('admin', 'admin@example.com');
        $employee = $this->makeUser('karyawan', 'employee@example.com');

        $this->get('/admin')->assertRedirect(route('admin.login'));

        $this->post('/admin/login', [
            'email' => $employee->email,
            'password' => 'password123',
        ])->assertSessionHasErrors('email');

        $this->post('/admin/login', [
            'email' => $admin->email,
            'password' => 'password123',
        ])->assertRedirect(route('admin.dashboard'));

        $this->get('/admin')->assertOk()->assertSee('Dashboard');
    }

    public function test_admin_web_can_manage_attendance_requests_and_accounts(): void
    {
        $admin = $this->makeUser('admin', 'admin@example.com');
        $employee = $this->makeUser('karyawan', 'employee@example.com');
        $this->actingAs($admin);

        $this->post('/admin/attendance/check-in')->assertRedirect();
        $this->post('/admin/attendance/check-out')->assertRedirect();
        $this->assertDatabaseHas('presensis', [
            'user_id' => $admin->id,
            'tanggal' => today()->toDateString(),
        ]);

        $this->post('/admin/requests', [
            'type' => 'cuti',
            'start_date' => today()->addDay()->toDateString(),
            'end_date' => today()->addDays(2)->toDateString(),
            'reason' => 'Keperluan keluarga',
        ])->assertRedirect();

        $request = EmployeeRequest::create([
            'user_id' => $employee->id,
            'type' => 'izin',
            'start_date' => today()->addDay()->toDateString(),
            'end_date' => today()->addDay()->toDateString(),
            'reason' => 'Keperluan',
        ]);
        $this->patch(route('admin.requests.decision', $request), [
            'status' => 'approved',
            'reviewer_note' => 'Disetujui',
        ])->assertRedirect();

        $this->post('/admin/users', [
            'name' => 'HRD User',
            'email' => 'hrd@example.com',
            'password' => 'password123',
            'role' => 'hrd',
        ])->assertRedirect();

        $this->assertDatabaseHas('employee_requests', [
            'id' => $request->id,
            'status' => 'approved',
            'reviewed_by' => $admin->id,
        ]);
        $this->assertDatabaseHas('users', ['email' => 'hrd@example.com', 'role' => 'hrd']);
    }

    public function test_web_profile_update_and_monthly_report_render(): void
    {
        $admin = $this->makeUser('admin', 'admin@example.com');
        $employee = $this->makeUser('karyawan', 'employee@example.com');
        Presensi::create([
            'user_id' => $employee->id,
            'tanggal' => today()->toDateString(),
            'jam_masuk' => '08:00:00',
            'jam_pulang' => '16:00:00',
        ]);
        $this->actingAs($admin);

        $this->get('/admin?month='.now()->format('Y-m'))
            ->assertOk()
            ->assertSee('Performa & laporan karyawan', false)
            ->assertSee('Kehadiran')
            ->assertSee('8j 0m');

        $this->put('/admin/profile', [
            'name' => 'Updated Admin',
            'email' => $admin->email,
        ])->assertRedirect();
        $this->assertDatabaseHas('users', ['id' => $admin->id, 'name' => 'Updated Admin']);
    }

    private function makeUser(string $role, string $email): User
    {
        return User::create([
            'name' => ucfirst($role).' User',
            'email' => $email,
            'password' => 'password123',
            'role' => $role,
        ]);
    }
}
