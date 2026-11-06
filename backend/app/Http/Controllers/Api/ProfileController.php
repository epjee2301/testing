<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProfileController
{
    public function show(Request $request)
    {
        return response()->json(['data' => $request->user()]);
    }

    public function update(Request $request)
    {
        $user = $request->user();
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
        ]);

        $user->name = $validated['name'];
        $user->email = $validated['email'];
        if (!empty($validated['password'])) {
            $user->password = $validated['password'];
        }
        $user->save();

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'data' => $user->fresh(),
        ]);
    }
}
