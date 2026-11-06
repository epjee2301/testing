<?php

namespace App\Contracts\FaceRecognition;

use App\Models\User;
use Illuminate\Http\UploadedFile;

interface FaceRecognitionProvider
{
    public function enroll(User $user, UploadedFile $image): void;

    public function verify(User $user, UploadedFile $image): bool;

    public function removeEnrollment(User $user): void;
}
