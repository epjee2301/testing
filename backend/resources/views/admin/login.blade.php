<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login Admin · LookIn Presensi</title>
    <style>
        :root{font-family:Inter,Segoe UI,Arial,sans-serif;color:#211d28;background:#f8f5fb}
        *{box-sizing:border-box}body{margin:0;min-height:100vh;display:grid;place-items:center;padding:24px}
        .card{width:min(100%,420px);background:#fff;border:1px solid #e8e0ee;border-radius:20px;padding:32px;box-shadow:0 16px 48px #29143b12}
        .mark{width:52px;height:52px;border-radius:16px;display:grid;place-items:center;background:#eee7fa;color:#6741a5;font-size:26px}
        h1{font-size:25px;margin:20px 0 6px}p{color:#706a78;margin:0 0 24px}
        label{display:block;font-weight:600;font-size:14px;margin:16px 0 7px}
        input{width:100%;padding:12px 14px;border:1px solid #d6cedd;border-radius:10px;font:inherit}
        button{width:100%;margin-top:22px;border:0;border-radius:10px;background:#6845a5;color:#fff;padding:13px;font:inherit;font-weight:700;cursor:pointer}
        .error{background:#fff0ef;color:#a52d25;border-radius:10px;padding:12px;margin:16px 0}
        .hint{font-size:13px;margin-top:18px}
    </style>
</head>
<body>
<main class="card">
    <div class="mark" aria-hidden="true">⌁</div>
    <h1>LookIn Presensi</h1>
    <p>Masuk ke panel web administrator.</p>
    @if ($errors->any())
        <div class="error" role="alert">{{ $errors->first() }}</div>
    @endif
    <form method="POST" action="{{ route('admin.login.submit') }}">
        @csrf
        <label for="email">Email admin</label>
        <input id="email" name="email" type="email" value="{{ old('email') }}" autocomplete="username" required autofocus>
        <label for="password">Password</label>
        <input id="password" name="password" type="password" autocomplete="current-password" required>
        <button type="submit">Masuk sebagai admin</button>
    </form>
    <p class="hint">Akun HRD dan karyawan masuk melalui aplikasi Flutter mobile.</p>
</main>
</body>
</html>
