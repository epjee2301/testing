<?php

namespace App\Http\Controllers\Api;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Laravel\Sanctum\PersonalAccessToken;
use LogicException;

class AuthController
{
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::validate($credentials)) {
            return response()->json([
                'message' => 'Email atau password salah',
            ], 401);
        }

        $user = Auth::getLastAttempted();

        if (! $user instanceof User) {
            throw new LogicException('The authentication provider must return an App\Models\User instance.');
        }

        if (! $user->is_active) {
            return response()->json(['message' => 'Akun ini sudah dinonaktifkan.'], 403);
        }

        if ($user->role === 'admin') {
            return response()->json([
                'message' => 'Akun admin masuk melalui web Laravel. Aplikasi mobile hanya untuk HRD dan karyawan.',
            ], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil',
            'token' => $token,
            'role' => $user->role,
            'user' => $user->only(['id', 'name', 'email', 'role']),
        ]);
    }

    public function logout(Request $request)
    {
        $token = $request->user()->currentAccessToken();

        if ($token instanceof PersonalAccessToken) {
            $token->delete();
        }

        return response()->json(['message' => 'Logout berhasil']);
    }
}
