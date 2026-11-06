<?php

namespace App\Http\Controllers\Api;

use App\Models\EmployeeRequest;
use App\Models\Presensi;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;

class HrdDashboardController
{
    public function __invoke(Request $request)
    {
        $today = today()->toDateString();
        $validated = $request->validate([
            'month' => ['nullable', 'date_format:Y-m'],
            'date' => ['nullable', 'date_format:Y-m-d'],
        ]);
        $statusDate = $validated['date'] ?? $today;
        $month = Carbon::createFromFormat('Y-m', $validated['month'] ?? now()->format('Y-m'));
        $monthStart = $month->copy()->startOfMonth();
        $monthEnd = $month->copy()->endOfMonth();

        $employees = User::query()
            ->where('role', 'karyawan')
            ->where('is_active', true);
        $employeeList = (clone $employees)->orderBy('name')->get(['id', 'name', 'email']);
        $employeeIds = $employeeList->pluck('id');
        $employeeCount = $employeeList->count();
        $presentCount = Presensi::query()
            ->whereDate('tanggal', $today)
            ->whereIn('user_id', $employeeIds)
            ->distinct('user_id')
            ->count('user_id');

        $todayAttendance = Presensi::query()
            ->whereDate('tanggal', $statusDate)
            ->whereIn('user_id', $employeeIds)
            ->get(['user_id', 'jam_masuk'])
            ->keyBy('user_id');

        $todayRequests = EmployeeRequest::query()
            ->whereIn('user_id', $employeeIds)
            ->where('status', 'approved')
            ->whereIn('type', ['cuti', 'izin', 'sakit'])
            ->whereDate('start_date', '<=', $statusDate)
            ->where(fn ($query) => $query
                ->whereNull('end_date')
                ->orWhereDate('end_date', '>=', $statusDate))
            ->orderByRaw("CASE type WHEN 'sakit' THEN 1 WHEN 'izin' THEN 2 ELSE 3 END")
            ->get(['user_id', 'type'])
            ->unique('user_id')
            ->keyBy('user_id');

        $employeeStatuses = $employeeList->map(function (User $employee) use ($todayAttendance, $todayRequests) {
            $attendance = $todayAttendance->get($employee->id);
            $activeRequest = $todayRequests->get($employee->id);

            return [
                'id' => $employee->id,
                'name' => $employee->name,
                'email' => $employee->email,
                'status' => $attendance
                    ? 'hadir'
                    : ($activeRequest?->type ?? 'alpa'),
                'jam_masuk' => $attendance?->jam_masuk,
            ];
        })->sortBy(fn (array $employee) => match ($employee['status']) {
            'hadir' => 0,
            'cuti' => 1,
            'sakit' => 2,
            'izin' => 3,
            default => 4,
        })->values();

        $employeeRequests = EmployeeRequest::query()
            ->whereHas('user', fn ($query) => $query
                ->where('role', 'karyawan')
                ->where('is_active', true));
        $activeRequests = fn (string $type) => (clone $employeeRequests)
            ->where('type', $type)
            ->where('status', 'approved')
            ->whereDate('start_date', '<=', $today)
            ->where(fn ($query) => $query
                ->whereNull('end_date')
                ->orWhereDate('end_date', '>=', $today))
            ->count();

        $notifications = (clone $employeeRequests)
            ->with('user:id,name')
            ->latest('created_at')
            ->limit(5)
            ->get(['id', 'user_id', 'type', 'start_date', 'end_date', 'status', 'created_at']);

        $weeklyAttendance = [];
        $weekStart = $monthStart->copy();
        $weekNumber = 1;
        while ($weekStart->lte($monthEnd)) {
            $weekEnd = $weekStart->copy()->addDays(6)->min($monthEnd);
            $weeklyAttendance[] = [
                'week' => 'M'.$weekNumber,
                'count' => Presensi::query()
                    ->whereBetween('tanggal', [
                        $weekStart->toDateString(),
                        $weekEnd->toDateString(),
                    ])
                    ->whereIn('user_id', $employeeIds)
                    ->count(),
            ];
            $weekStart->addDays(7);
            $weekNumber++;
        }

        return response()->json([
            'data' => [
                'summary' => [
                    'employee_count' => $employeeCount,
                    'present_count' => $presentCount,
                    'attendance_rate' => $employeeCount > 0
                        ? (int) round(($presentCount / $employeeCount) * 100)
                        : 0,
                    'active_cuti_count' => $activeRequests('cuti'),
                    'active_sakit_count' => $activeRequests('sakit'),
                    'pending_request_count' => (clone $employeeRequests)
                        ->where('status', 'pending')
                        ->count(),
                    'monthly_attendance_count' => Presensi::query()
                        ->whereBetween('tanggal', [
                            $monthStart->toDateString(),
                            $monthEnd->toDateString(),
                        ])
                        ->whereIn('user_id', $employeeIds)
                        ->count(),
                    'monthly_request_count' => (clone $employeeRequests)
                        ->whereBetween('created_at', [$monthStart, $monthEnd])
                        ->count(),
                ],
                'notifications' => $notifications,
                'employee_statuses' => $employeeStatuses,
                'weekly_attendance' => $weeklyAttendance,
                'status_date' => $statusDate,
                'month' => $month->format('Y-m'),
                'date' => $today,
            ],
        ]);
    }
}
