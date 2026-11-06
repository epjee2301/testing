<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Presensi extends Model
{
    protected $fillable = [
        'user_id', 'tanggal', 'jam_masuk', 'foto_masuk', 'jam_pulang', 'foto_pulang'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}