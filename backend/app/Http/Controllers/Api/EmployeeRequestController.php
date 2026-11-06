<?php

namespace App\Http\Controllers\Api;

use App\Models\EmployeeRequest;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class EmployeeRequestController
{
    public function index(Request $request)
    {
        $query = EmployeeRequest::query()->with('user:id,name,email')->latest();

        if ($request->user()->role === 'hrd') {
            $query->whereHas('user', fn ($userQuery) => $userQuery->where('role', 'karyawan'));
        } else {
            $query->where('user_id', $request->user()->id);
        }

        return response()->json(['data' => $query->get()]);
    }

    public function store(Request $request)
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

        $employeeRequest = EmployeeRequest::create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        return response()->json([
            'message' => 'Pengajuan berhasil dikirim.',
            'data' => $employeeRequest,
        ], 201);
    }

    public function decide(Request $request, EmployeeRequest $employeeRequest)
    {
        abort_unless($employeeRequest->user()->where('role', 'karyawan')->exists(), 404);

        if ($employeeRequest->status !== 'pending') {
            return response()->json([
                'message' => 'Pengajuan ini sudah diputuskan.',
            ], 422);
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

        return response()->json([
            'message' => 'Keputusan pengajuan tersimpan.',
            'data' => $employeeRequest->fresh()->load('user:id,name,email'),
        ]);
    }

}
