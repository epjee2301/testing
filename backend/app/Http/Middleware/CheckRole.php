<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        // 1. Pastikan user sudah memiliki token yang valid (sudah login)
        if (! Auth::check()) {
            return response()->json(['message' => 'Unauthorized. Silakan login.'], 401);
        }

        // 2. Ambil data role dari user yang sedang login
        $userRole = Auth::user()->role;

        // 3. Cek apakah role user ada di dalam daftar role yang diizinkan untuk endpoint ini
        if (! in_array($userRole, $roles)) {
            return response()->json(['message' => 'Forbidden. Anda tidak memiliki akses ke halaman ini.'], 403);
        }

        // 4. Lolos pengecekan, teruskan request ke Controller
        return $next($request);
    }
}
