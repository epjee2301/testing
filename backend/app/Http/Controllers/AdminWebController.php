<?php

namespace App\Http\Controllers;

use App\Models\EmployeeRequest;
use App\Models\Presensi;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class AdminWebController extends Controller
{
    public function loginForm()
    {
        if (Auth::check() && Auth::user()->role === 'admin') {
            return redirect()->route('admin.dashboard');
        }

        return view('admin.login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::attempt($credentials)) {
            return back()->withErrors(['email' => 'Email atau password salah.'])->onlyInput('email');
        }

        $request->session()->regenerate();
        $user = Auth::user();

        if (! $user->is_active || $user->role !== 'admin') {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return back()->withErrors([
                'email' => 'Halaman ini hanya untuk admin. HRD dan karyawan menggunakan aplikasi mobile.',
            ])->onlyInput('email');
        }

        return redirect()->intended(route('admin.dashboard'));
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }

    public function dashboard(Request $request)
    {
        $validated = $request->validate(['month' => ['nullable', 'date_format:Y-m']]);
        $month = Carbon::createFromFormat('Y-m', $validated['month'] ?? now()->format('Y-m'));
        $start = $month->copy()->startOfMonth()->toDateString();
        $end = $month->copy()->endOfMonth()->toDateString();
        $workDayEnd = $month->isCurrentMonth()
            ? $month->copy()->min(today())
            : $month->copy()->endOfMonth();
        $workDaysInMonth = 0;
        $workDay = $month->copy()->startOfMonth();
        while ($workDay->lte($workDayEnd)) {
            if ($workDay->isWeekday()) {
                $workDaysInMonth++;
            }
            $workDay->addDay();
        }

        $attendance = Presensi::with('user:id,name,email,role')
            ->whereBetween('tanggal', [$start, $end])
            ->orderByDesc('tanggal')
            ->get();

        $requests = EmployeeRequest::with(['user:id,name,email,role', 'reviewer:id,name'])
            ->whereDate('start_date', '<=', $end)
            ->where(function ($query) use ($start) {
                $query->whereNull('end_date')->orWhereDate('end_date', '>=', $start);
            })
            ->latest()
            ->get();

        $users = User::whereIn('role', ['hrd', 'karyawan'])
            ->orderBy('role')
            ->orderBy('name')
            ->get();

        $employees = User::where('role', 'karyawan')->where('is_active', true)->orderBy('name')->get();
        $attendanceByUser = $attendance->where('user.role', 'karyawan')->groupBy('user_id');
        $requestsByUser = $requests->where('user.role', 'karyawan')->groupBy('user_id');
        $reports = $employees->map(function (User $employee) use ($attendanceByUser, $requestsByUser, $start, $end, $workDaysInMonth) {
            $days = $attendanceByUser->get($employee->id, collect());
            $workMinutes = $days->sum(function (Presensi $item) {
                if (! $item->jam_pulang) {
                    return 0;
                }

                $startAt = Carbon::parse($item->tanggal.' '.$item->jam_masuk);
                $endAt = Carbon::parse($item->tanggal.' '.$item->jam_pulang);
                if ($endAt->lessThan($startAt)) {
                    $endAt->addDay();
                }

                return max(0, intdiv($endAt->timestamp - $startAt->timestamp, 60));
            });
            $employeeRequests = $requestsByUser->get($employee->id, collect());
            $leaveDays = $employeeRequests
                ->where('status', 'approved')
                ->whereIn('type', ['cuti', 'izin', 'sakit'])
                ->sum(function (EmployeeRequest $employeeRequest) use ($start, $end) {
                    $leaveStart = Carbon::parse($employeeRequest->start_date)->max(Carbon::parse($start));
                    $leaveEnd = Carbon::parse($employeeRequest->end_date ?? $employeeRequest->start_date)->min(Carbon::parse($end));

                    return $leaveStart->diffInDays($leaveEnd) + 1;
                });

            return [
                'user' => $employee,
                'attendance_days' => $days->count(),
                'attendance_rate' => $workDaysInMonth > 0
                    ? round(min(100, ($days->count() / $workDaysInMonth) * 100), 1)
                    : 0,
                'work_minutes' => $workMinutes,
                'average_work_minutes' => $days->isNotEmpty()
                    ? (int) round($workMinutes / $days->count())
                    : 0,
                'leave_days' => $leaveDays,
                'approved_overtime' => $employeeRequests->where('status', 'approved')->where('type', 'lembur')->count(),
            ];
        });

        return view('admin.dashboard', [
            'month' => $month->format('Y-m'),
            'attendance' => $attendance,
            'requests' => $requests,
            'users' => $users,
            'reports' => $reports,
            'workDaysInMonth' => $workDaysInMonth,
            'pendingCount' => $requests->where('status', 'pending')->count(),
        ]);
    }

    public function attendance(Request $request, string $action)
    {
        abort_unless(in_array($action, ['check-in', 'check-out'], true), 404);
        $today = today()->toDateString();
        $attendance = Presensi::where('user_id', $request->user()->id)
            ->where('tanggal', $today)
            ->first();

        if ($action === 'check-in') {
            if ($attendance) {
                return back()->with('error', 'Anda sudah melakukan absen masuk hari ini.');
            }

            Presensi::create([
                'user_id' => $request->user()->id,
                'tanggal' => $today,
                'jam_masuk' => now()->toTimeString(),
            ]);

            return back()->with('success', 'Absen masuk berhasil dicatat.');
        }

        if (! $attendance) {
            return back()->with('error', 'Catat absen masuk sebelum absen keluar.');
        }
        if ($attendance->jam_pulang) {
            return back()->with('error', 'Anda sudah melakukan absen keluar hari ini.');
        }

        $attendance->update(['jam_pulang' => now()->toTimeString()]);

        return back()->with('success', 'Absen keluar berhasil dicatat.');
    }

    public function submitRequest(Request $request)
    {
        $validated = $request->validate([
            'type' => ['required', Rule::in(['cuti', 'izin', 'sakit', 'lembur'])],
            'start_date' => ['required', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'start_time' => ['required_if:type,lembur', 'nullable', 'date_format:H:i'],
            'end_time' => ['required_if:type,lembur', 'nullable', 'date_format:H:i', 'after:start_time'],
            'reason' => ['required', 'string', 'max:2000'],
        ]);

        if ($validated['type'] !== 'lembur') {
            $validated['end_date'] ??= $validated['start_date'];
            $validated['start_time'] = null;
            $validated['end_time'] = null;
        }

        EmployeeRequest::create([...$validated, 'user_id' => $request->user()->id]);

        return back()->with('success', 'Pengajuan berhasil dikirim.');
    }

    public function decideRequest(Request $request, EmployeeRequest $employeeRequest)
    {
        if ($employeeRequest->user_id === $request->user()->id) {
            return back()->with('error', 'Anda tidak dapat menyetujui pengajuan sendiri.');
        }
        if ($employeeRequest->status !== 'pending') {
            return back()->with('error', 'Pengajuan ini sudah diputuskan.');
        }

        $validated = $request->validate([
            'status' => ['required', Rule::in(['approved', 'rejected'])],
            'reviewer_note' => ['nullable', 'string', 'max:2000'],
        ]);

        $employeeRequest->update([
            ...$validated,
            'reviewed_by' => $request->user()->id,
            'reviewed_at' => now(),
        ]);

        return back()->with('success', 'Keputusan pengajuan tersimpan.');
    }

    public function storeUser(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['required', Rule::in(['hrd', 'karyawan'])],
        ]);

        User::create([...$validated, 'is_active' => true]);

        return back()->with('success', 'Pengguna berhasil ditambahkan.');
    }

    public function updateUser(Request $request, User $user)
    {
        abort_unless(in_array($user->role, ['hrd', 'karyawan'], true), 403);
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            'role' => ['required', Rule::in(['hrd', 'karyawan'])],
            'password' => ['nullable', 'string', 'min:8'],
        ]);

        if (empty($validated['password'])) {
            unset($validated['password']);
        }
        $user->update($validated);

        return back()->with('success', 'Pengguna berhasil diperbarui.');
    }

    public function toggleUser(User $user)
    {
        abort_unless(in_array($user->role, ['hrd', 'karyawan'], true), 403);
        $user->update(['is_active' => ! $user->is_active]);
        if (! $user->is_active) {
            $user->tokens()->delete();
        }

        return back()->with('success', $user->is_active ? 'Akun diaktifkan.' : 'Akun dinonaktifkan.');
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
        ]);

        if (empty($validated['password'])) {
            unset($validated['password']);
        }
        $user->update($validated);

        return back()->with('success', 'Profil berhasil diperbarui.');
    }
}
