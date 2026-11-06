# Face recognition integration

This module is the integration boundary for the Information Systems team. The
face-recognition algorithm is intentionally not implemented here. Existing
attendance continues to work as before until a provider is implemented and
explicitly connected to the API.

## Code location

- Contract: `app/Contracts/FaceRecognition/FaceRecognitionProvider.php`
- Provider implementation: `app/Services/FaceRecognition/`
- API integration: `app/Http/Controllers/Api/` and `routes/api.php`
- Provider binding: `app/Providers/AppServiceProvider.php`

Implement `FaceRecognitionProvider` with these operations:

- `enroll(User $user, UploadedFile $image)`: create or replace the user's face
  enrollment; throw an exception if enrollment cannot be completed.
- `verify(User $user, UploadedFile $image)`: compare a live capture with that
  user's enrollment and return `true` only when verification passes. A mismatch
  returns `false`; infrastructure or processing errors must throw.
- `removeEnrollment(User $user)`: remove the user's enrollment.

Bind the implementation in `AppServiceProvider::register()` only after the
provider is ready. Do not bind a permissive or always-successful fallback.

## API integration plan

1. Add authenticated enrollment and enrollment-removal endpoints for the
   employee's own account.
2. Before recording check-in or check-out, pass the submitted live image and
   authenticated user to `verify`.
3. Reject mismatches and provider errors without creating or updating an
   attendance record. Do not fall back to the existing optional-photo behavior
   when face verification is enabled.
4. Preserve the existing `foto` field only if the product still needs a separate
   attendance evidence photo; it is not itself face verification.
5. Add feature tests for successful enrollment, mismatch, successful check-in
   and check-out, provider failure, missing enrollment, and attempts to access
   another user's enrollment.

## Privacy and security requirements

- Obtain informed consent before collecting biometric data and provide an
  enrollment-removal flow.
- Do not log, expose in API responses, or retain uploaded face images by
  default. Store only the minimum required biometric template/reference, with
  encryption, restricted access, and an agreed retention/deletion policy.
- Implement liveness and anti-spoof checks in the provider; a still image match
  alone is not sufficient for attendance verification.
- Keep thresholds and matching decisions on the server. Never trust a
  client-provided "verified" flag or score.
- Document the chosen library/model, runtime dependencies, and deployment
  requirements before adding them to the application.

## Current status

The current attendance endpoints accept an optional `foto` upload and do not
perform enrollment, face matching, or liveness checks. The contract above is a
collaboration seam, not a claim that face-based attendance is active.
