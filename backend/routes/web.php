<?php

use App\Http\Controllers\AdminWebController;
use Illuminate\Support\Facades\Route;

Route::get('/', [AdminWebController::class, 'loginForm']);
Route::get('/admin/login', [AdminWebController::class, 'loginForm'])->name('admin.login');
Route::post('/admin/login', [AdminWebController::class, 'login'])->middleware('throttle:10,1')->name('admin.login.submit');

Route::middleware(['auth', 'role:admin'])->prefix('admin')->name('admin.')->group(function () {
    Route::get('/', [AdminWebController::class, 'dashboard'])->name('dashboard');
    Route::post('/logout', [AdminWebController::class, 'logout'])->name('logout');
    Route::post('/attendance/{action}', [AdminWebController::class, 'attendance'])->name('attendance');
    Route::post('/requests', [AdminWebController::class, 'submitRequest'])->name('requests.store');
    Route::patch('/requests/{employeeRequest}/decision', [AdminWebController::class, 'decideRequest'])->name('requests.decision');
    Route::post('/users', [AdminWebController::class, 'storeUser'])->name('users.store');
    Route::put('/users/{user}', [AdminWebController::class, 'updateUser'])->name('users.update');
    Route::patch('/users/{user}/toggle', [AdminWebController::class, 'toggleUser'])->name('users.toggle');
    Route::put('/profile', [AdminWebController::class, 'updateProfile'])->name('profile.update');
});
