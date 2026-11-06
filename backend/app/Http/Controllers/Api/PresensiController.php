<?php

namespace App\Http\Controllers\Api;

use App\Models\Presensi;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PresensiController
{
    public function index(Request $request)
    {
        $validated = $request->validate([
            'month' => ['nullable', 'date_format:Y-m'],
        ]);
        $month = Carbon::createFromFormat('Y-m', $validated['month'] ?? now()->format('Y-m'));

        $attendance = Presensi::query()
            ->where('user_id', Auth::id())
            ->whereBetween('tanggal', [
                $month->copy()->startOfMonth()->toDateString(),
                $month->copy()->endOfMonth()->toDateString(),
            ])
            ->orderByDesc('tanggal')
            ->get();

        return response()->json(['data' => $attendance]);
    }

    public function checkIn(Request $request)
    {
        $validated = $request->validate([
            'foto' => ['nullable', 'image', 'mimes:jpeg,png,jpg', 'max:2048'],
        ]);

        /** @var User $user */
        $user = Auth::user();
        $hariIni = Carbon::today()->toDateString();

        if (Presensi::where('user_id', $user->id)->where('tanggal', $hariIni)->exists()) {
            return response()->json(['message' => 'Anda sudah melakukan Check In hari ini.'], 409);
        }

        $fotoPath = ($validated['foto'] ?? null)?->store('presensi', 'public');

        $presensi = Presensi::create([
            'user_id' => $user->id,
            'tanggal' => $hariIni,
            'jam_masuk' => Carbon::now()->toTimeString(),
            'foto_masuk' => $fotoPath,
        ]);

        return response()->json([
            'message' => 'Check In berhasil',
            'data' => $presensi,
        ], 201);
    }

    public function checkOut(Request $request)
    {
        $validated = $request->validate([
            'foto' => ['nullable', 'image', 'mimes:jpeg,png,jpg', 'max:2048'],
        ]);

        /** @var User $user */
        $user = Auth::user();
        $hariIni = Carbon::today()->toDateString();

        $presensi = Presensi::where('user_id', $user->id)
            ->where('tanggal', $hariIni)
            ->first();

        if (! $presensi) {
            return response()->json(['message' => 'Anda belum Check In hari ini.'], 409);
        }

        if ($presensi->jam_pulang) {
            return response()->json(['message' => 'Anda sudah melakukan Check Out hari ini.'], 409);
        }

        $fotoPath = ($validated['foto'] ?? null)?->store('presensi', 'public');

        $presensi->update([
            'jam_pulang' => Carbon::now()->toTimeString(),
            'foto_pulang' => $fotoPath,
        ]);

        return response()->json([
            'message' => 'Check Out berhasil',
            'data' => $presensi,
        ], 200);
    }
}
