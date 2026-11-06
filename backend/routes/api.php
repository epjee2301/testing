<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EmployeeRequestController;
use App\Http\Controllers\Api\HrdDashboardController;
use App\Http\Controllers\Api\PresensiController;
use App\Http\Controllers\Api\ProfileController;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']);

// The mobile API is reserved for HRD and employee accounts.
Route::middleware(['auth:sanctum', 'role:hrd,karyawan'])->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);

    Route::get('/hrd/dashboard', HrdDashboardController::class)
        ->middleware('role:hrd');
    Route::get('/attendance', [PresensiController::class, 'index']);
    Route::post('/attendance/check-in', [PresensiController::class, 'checkIn']);
    Route::post('/attendance/check-out', [PresensiController::class, 'checkOut']);
    Route::get('/requests', [EmployeeRequestController::class, 'index']);
    Route::post('/requests', [EmployeeRequestController::class, 'store']);
});

Route::middleware(['auth:sanctum', 'role:hrd'])->patch(
    '/requests/{employeeRequest}/decision',
    [EmployeeRequestController::class, 'decide']
);
