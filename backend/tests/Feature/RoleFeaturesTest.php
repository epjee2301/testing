<?php

namespace Tests\Feature;

use App\Models\EmployeeRequest;
use App\Models\Presensi;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RoleFeaturesTest extends TestCase
{
    use RefreshDatabase;

    public function test_all_roles_can_record_and_view_their_own_attendance(): void
    {
        foreach (['hrd', 'karyawan'] as $role) {
            $user = $this->makeUser($role);
            Sanctum::actingAs($user);

            $this->postJson('/api/attendance/check-in')->assertCreated();
            $this->postJson('/api/attendance/check-out')->assertOk();
            $this->getJson('/api/attendance?month='.now()->format('Y-m'))
                ->assertOk()
                ->assertJsonCount(1, 'data');
        }

        $this->assertDatabaseCount('presensis', 2);
    }

    public function test_mobile_user_can_submit_and_view_their_own_request(): void
    {
        $employee = $this->makeUser('karyawan');
        Sanctum::actingAs($employee);

        $response = $this->postJson('/api/requests', [
            'type' => 'cuti',
            'start_date' => now()->addDay()->toDateString(),
            'end_date' => now()->addDays(2)->toDateString(),
            'reason' => 'Keperluan keluarga',
        ])->assertCreated();

        $requestId = $response->json('data.id');
        $this->getJson('/api/requests')
            ->assertOk()
            ->assertJsonPath('data.0.id', $requestId)
            ->assertJsonPath('data.0.status', 'pending');
        $this->assertDatabaseHas('employee_requests', [
            'id' => $requestId,
            'status' => 'pending',
        ]);
    }

    public function test_hrd_can_review_employee_requests_and_employee_cannot_decide_them(): void
    {
        $employee = $this->makeUser('karyawan');
        $hrd = $this->makeUser('hrd');
        $employeeRequest = EmployeeRequest::create([
            'user_id' => $employee->id,
            'type' => 'cuti',
            'start_date' => now()->addDay()->toDateString(),
            'end_date' => now()->addDay()->toDateString(),
            'reason' => 'Keperluan keluarga',
        ]);
        $rejectedRequest = EmployeeRequest::create([
            'user_id' => $employee->id,
            'type' => 'lembur',
            'start_date' => now()->toDateString(),
            'end_date' => now()->toDateString(),
            'start_time' => '17:00',
            'end_time' => '19:00',
            'reason' => 'Penyelesaian pekerjaan',
        ]);

        Sanctum::actingAs($employee);
        $this->getJson('/api/requests')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.user_id', $employee->id);
        $this->patchJson("/api/requests/{$employeeRequest->id}/decision", [
            'status' => 'approved',
        ])->assertForbidden();

        Sanctum::actingAs($hrd);
        $this->getJson('/api/requests')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.user.name', $employee->name);
        $this->patchJson("/api/requests/{$employeeRequest->id}/decision", [
            'status' => 'approved',
            'reviewer_note' => 'Disetujui.',
        ])->assertOk()
            ->assertJsonPath('data.status', 'approved')
            ->assertJsonPath('data.reviewer_note', 'Disetujui.');
        $this->patchJson("/api/requests/{$rejectedRequest->id}/decision", [
            'status' => 'rejected',
            'reviewer_note' => 'Mohon ajukan kembali dengan detail.',
        ])->assertOk()
            ->assertJsonPath('data.status', 'rejected')
            ->assertJsonPath('data.reviewer_note', 'Mohon ajukan kembali dengan detail.');

        $this->assertDatabaseHas('employee_requests', [
            'id' => $employeeRequest->id,
            'status' => 'approved',
            'reviewed_by' => $hrd->id,
        ]);
        $this->assertDatabaseHas('employee_requests', [
            'id' => $rejectedRequest->id,
            'status' => 'rejected',
            'reviewed_by' => $hrd->id,
        ]);
    }

    public function test_hrd_dashboard_returns_employee_attendance_request_and_notification_summaries(): void
    {
        $hrd = $this->makeUser('hrd');
        $employee = $this->makeUser('karyawan');
        $inactiveEmployee = $this->makeUser('karyawan');
        $inactiveEmployee->update(['is_active' => false]);

        Presensi::create([
            'user_id' => $employee->id,
            'tanggal' => today()->toDateString(),
            'jam_masuk' => '08:00:00',
        ]);
        Presensi::create([
            'user_id' => $hrd->id,
            'tanggal' => today()->toDateString(),
            'jam_masuk' => '08:00:00',
        ]);
        EmployeeRequest::create([
            'user_id' => $employee->id,
            'type' => 'cuti',
            'start_date' => today()->toDateString(),
            'end_date' => today()->toDateString(),
            'reason' => 'Cuti',
            'status' => 'approved',
        ]);
        EmployeeRequest::create([
            'user_id' => $employee->id,
            'type' => 'sakit',
            'start_date' => today()->toDateString(),
            'end_date' => today()->toDateString(),
            'reason' => 'Sakit',
            'status' => 'approved',
        ]);
        EmployeeRequest::create([
            'user_id' => $employee->id,
            'type' => 'izin',
            'start_date' => today()->toDateString(),
            'end_date' => today()->toDateString(),
            'reason' => 'Izin',
        ]);

        Sanctum::actingAs($hrd);
        $this->getJson('/api/hrd/dashboard')
            ->assertOk()
            ->assertJsonPath('data.summary.employee_count', 1)
            ->assertJsonPath('data.summary.present_count', 1)
            ->assertJsonPath('data.summary.attendance_rate', 100)
            ->assertJsonPath('data.summary.active_cuti_count', 1)
            ->assertJsonPath('data.summary.active_sakit_count', 1)
            ->assertJsonPath('data.summary.pending_request_count', 1)
            ->assertJsonPath('data.summary.monthly_attendance_count', 1)
            ->assertJsonPath('data.summary.monthly_request_count', 3)
            ->assertJsonPath('data.notifications.0.user.name', $employee->name)
            ->assertJsonPath('data.employee_statuses.0.id', $employee->id)
            ->assertJsonPath('data.employee_statuses.0.status', 'hadir')
            ->assertJsonPath('data.weekly_attendance.0.week', 'M1')
            ->assertJsonPath('data.weekly_attendance.0.count', 1)
            ->assertJsonPath('data.month', now()->format('Y-m'))
            ->assertJsonPath('data.status_date', today()->toDateString());

        Sanctum::actingAs($employee);
        $this->getJson('/api/hrd/dashboard')->assertForbidden();
    }

    public function test_hrd_dashboard_can_load_a_selected_month_and_validates_the_month_format(): void
    {
        $hrd = $this->makeUser('hrd');
        $employee = $this->makeUser('karyawan');
        $employeeOnLeave = $this->makeUser('karyawan');
        $previousMonth = now()->subMonth();
        $statusDate = $previousMonth->copy()->startOfMonth()->addDays(5);
        Presensi::create([
            'user_id' => $employee->id,
            'tanggal' => $previousMonth->copy()->startOfMonth()->toDateString(),
            'jam_masuk' => '08:00:00',
        ]);
        EmployeeRequest::create([
            'user_id' => $employeeOnLeave->id,
            'type' => 'sakit',
            'start_date' => $statusDate->toDateString(),
            'end_date' => $statusDate->toDateString(),
            'reason' => 'Sakit',
            'status' => 'approved',
        ]);
        Sanctum::actingAs($hrd);

        $this->getJson('/api/hrd/dashboard?month='.$previousMonth->format('Y-m').'&date='.$statusDate->toDateString())
            ->assertOk()
            ->assertJsonPath('data.summary.monthly_attendance_count', 1)
            ->assertJsonPath('data.month', $previousMonth->format('Y-m'))
            ->assertJsonPath('data.status_date', $statusDate->toDateString())
            ->assertJsonFragment([
                'id' => $employeeOnLeave->id,
                'status' => 'sakit',
            ]);

        $this->getJson('/api/hrd/dashboard?month=invalid')->assertUnprocessable();
        $this->getJson('/api/hrd/dashboard?date=invalid')->assertUnprocessable();
    }

    public function test_admin_management_and_approval_are_not_exposed_on_mobile_api(): void
    {
        $employee = $this->makeUser('karyawan');
        Sanctum::actingAs($employee);

        $this->getJson('/api/admin/users')->assertNotFound();
        $this->patchJson('/api/admin/requests/1/decision', [
            'status' => 'approved',
        ])->assertNotFound();
    }

    public function test_authenticated_user_can_update_their_profile(): void
    {
        $user = $this->makeUser('karyawan');
        Sanctum::actingAs($user);

        $this->putJson('/api/profile', [
            'name' => 'Updated Employee',
            'email' => $user->email,
        ])->assertOk()
            ->assertJsonPath('data.name', 'Updated Employee');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated Employee',
        ]);
    }

    private function makeUser(string $role): User
    {
        static $index = 0;
        $index++;

        return User::create([
            'name' => ucfirst($role).' User',
            'email' => "{$role}{$index}@example.com",
            'password' => 'password123',
            'role' => $role,
        ]);
    }
}
