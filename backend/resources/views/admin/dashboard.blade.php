<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Admin · LookIn Presensi</title>
    <style>
        :root{font-family:Inter,Segoe UI,Arial,sans-serif;color:#233247;background:#f1f7fb;scroll-behavior:smooth}
        *{box-sizing:border-box}body{margin:0}.app-shell{min-height:100vh}
        a{color:#1769c2;text-decoration:none}.sidebar{position:fixed;inset:0 auto 0 0;width:220px;background:#fff;border-right:1px solid #e3edf4;padding:18px 14px;display:flex;flex-direction:column;z-index:3}
        .brand{display:flex;align-items:center;gap:7px;padding:0 6px 24px;color:#182332;font-size:19px;font-weight:800}.brand-mark{color:#1478d4;font-size:24px}
        .sidebar-label{padding:8px 12px;color:#91a1b1;font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase}
        .sidebar nav{display:grid;gap:4px}.sidebar nav a{display:flex;align-items:center;gap:11px;padding:11px 12px;border-radius:8px;color:#65768a;font-size:13px;font-weight:600}
        .sidebar nav a:hover,.sidebar nav a.active{background:#e8f3ff;color:#1478d4}.sidebar nav a.active{box-shadow:inset 3px 0 #1478d4}
        .sidebar-user{margin-top:auto;border-top:1px solid #edf2f6;padding:16px 5px 0;display:flex;align-items:center;gap:10px}
        .avatar{width:34px;height:34px;border-radius:50%;display:grid;place-items:center;background:#e4f1ff;color:#1478d4;font-weight:700}
        .sidebar-user strong,.sidebar-user small{display:block}.sidebar-user strong{font-size:12px}.sidebar-user small{margin-top:3px;color:#91a1b1;font-size:11px}
        .workspace{min-height:100vh;margin-left:220px}.topbar{height:64px;background:#fff;border-bottom:1px solid #e3edf4;padding:0 28px;display:flex;align-items:center;justify-content:flex-end;gap:12px}
        .topbar .account{display:flex;align-items:center;gap:8px;color:#45576a;font-size:12px;font-weight:600}.topbar .logout{background:transparent;color:#66798c;padding:8px}
        main{max-width:1440px;margin:auto;padding:28px 28px 70px}.heading{display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap}
        h1{margin:0;font-size:26px;color:#203248}h2{font-size:19px;margin:0 0 16px;color:#26384d}h3{font-size:15px;margin:0 0 12px;color:#344a60}.muted{color:#8595a5}
        section{scroll-margin-top:22px;margin-top:30px}.insights-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px}
        .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:14px}
        .card{background:#fff;border:1px solid #dce9f2;border-radius:12px;padding:17px;box-shadow:0 3px 12px #24507408}
        .insight-card{min-height:115px;position:relative;overflow:hidden}.insight-card .label{color:#71849a;font-size:12px}.insight-card .metric{font-size:27px;font-weight:750;margin:10px 0 4px;color:#2d5f9a}
        .insight-card .detail{font-size:11px;color:#91a1b1}.insight-icon{position:absolute;right:15px;top:16px;color:#98cbe9;font-size:20px}
        .metric{font-size:30px;font-weight:750;margin:8px 0}.notice{padding:12px 16px;border-radius:10px;margin:14px 0}.success{background:#e8f7ed;color:#20663a}.error{background:#fff0ef;color:#a52d25}
        .scroll{overflow:auto;border:1px solid #dce9f2;border-radius:12px;background:#fff}table{width:100%;border-collapse:collapse;min-width:720px}th,td{text-align:left;padding:12px 14px;border-bottom:1px solid #edf2f6;vertical-align:top}th{font-size:13px;color:#64788d;background:#f8fbfd}td small{display:block;color:#8595a5;margin-top:4px}
        form.inline{display:inline-flex;align-items:center;gap:7px;flex-wrap:wrap}form.stack{display:grid;gap:11px}
        input,select,textarea{font:inherit;border:1px solid #d4e0e9;border-radius:8px;padding:10px 11px;background:white;max-width:100%}input[type=date],input[type=time]{padding:9px}
        textarea{min-height:74px;resize:vertical}.fields{display:grid;grid-template-columns:repeat(auto-fit,minmax(175px,1fr));gap:10px}.status{display:inline-block;padding:4px 8px;border-radius:20px;background:#edf2f6;font-size:12px}
        button,.button{border:0;border-radius:8px;background:#1976d2;color:#fff;padding:10px 14px;font:inherit;font-weight:650;cursor:pointer}
        button.secondary{background:#e9f2fa;color:#38536c}button.danger{background:#ad3d3d}
        .pending{background:#fff3d8;color:#805400}.approved{background:#e8f7ed;color:#20663a}.rejected{background:#fff0ef;color:#a52d25}
        @media(max-width:900px){.insights-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}
        @media(max-width:700px){.sidebar{position:static;width:auto;padding:12px 14px;border-right:0;border-bottom:1px solid #e3edf4}.brand{padding:0 5px 10px}.sidebar-label,.sidebar-user{display:none}.sidebar nav{display:flex;overflow-x:auto}.sidebar nav a{white-space:nowrap;padding:9px}.sidebar nav a.active{box-shadow:inset 0 -3px #1478d4}.workspace{margin-left:0}.topbar{height:52px;padding:0 16px}.topbar .account{margin-right:auto}.topbar .logout{padding:7px}main{padding:22px 16px 48px}.heading form{width:100%}.heading input{flex:1}.insights-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}
        @media(max-width:420px){.insights-grid{grid-template-columns:1fr 1fr;gap:8px}.insight-card{padding:13px;min-height:108px}.insight-card .metric{font-size:23px}.insight-icon{right:11px;top:12px}}
    </style>
</head>
<body>
<div class="app-shell">
<aside class="sidebar">
    <div class="brand"><span class="brand-mark">◉</span>LookIn</div>
    <div class="sidebar-label">Menu admin</div>
    <nav aria-label="Navigasi admin">
        <a class="active" href="#overview"><span>▦</span>Dashboard</a>
        <a href="#attendance"><span>◷</span>Monitoring</a>
        <a href="#reports"><span>▤</span>Laporan</a>
        <a href="#requests"><span>▧</span>Pengajuan</a>
        <a href="#users"><span>♙</span>Pengguna</a>
        <a href="#profile"><span>⚙</span>Profil</a>
    </nav>
    <div class="sidebar-user">
        <div class="avatar">{{ mb_strtoupper(mb_substr(auth()->user()->name, 0, 1)) }}</div>
        <div><strong>{{ auth()->user()->name }}</strong><small>Administrator</small></div>
    </div>
</aside>
<div class="workspace">
<header class="topbar">
    <div class="account"><div class="avatar">{{ mb_strtoupper(mb_substr(auth()->user()->name, 0, 1)) }}</div>{{ auth()->user()->name }}</div>
    <form method="POST" action="{{ route('admin.logout') }}">@csrf<button class="logout" type="submit">Keluar</button></form>
</header>
<main>
    <div class="heading">
        <div><h1>Dashboard</h1><p class="muted">Halo, {{ auth()->user()->name }}. Berikut ringkasan aktivitas tim.</p></div>
        <form method="GET" action="{{ route('admin.dashboard') }}" class="inline">
            <label for="month">Periode laporan</label>
            <input id="month" name="month" type="month" value="{{ $month }}">
            <button type="submit">Tampilkan</button>
        </form>
    </div>
    @if (session('success'))<div class="notice success" role="status">{{ session('success') }}</div>@endif
    @if (session('error'))<div class="notice error" role="alert">{{ session('error') }}</div>@endif
    @if ($errors->any())<div class="notice error" role="alert">{{ $errors->first() }}</div>@endif

    <section id="overview">
        @php
            $averageAttendanceRate = $reports->isNotEmpty() ? $reports->avg('attendance_rate') : 0;
        @endphp
        <h2>Insights</h2>
        <div class="insights-grid">
            <article class="card insight-card"><span class="label">Rata-rata kehadiran</span><span class="insight-icon">◒</span><div class="metric">{{ number_format($averageAttendanceRate, 1) }}%</div><span class="detail">Karyawan aktif · {{ $month }}</span></article>
            <article class="card insight-card"><span class="label">Pengajuan menunggu</span><span class="insight-icon">◷</span><div class="metric">{{ $pendingCount }}</div><span class="detail">Perlu ditinjau</span></article>
            <article class="card insight-card"><span class="label">Karyawan aktif</span><span class="insight-icon">♙</span><div class="metric">{{ $reports->count() }}</div><span class="detail">Terdaftar di sistem</span></article>
            <article class="card insight-card"><span class="label">Total aktivitas presensi</span><span class="insight-icon">▤</span><div class="metric">{{ $attendance->count() }}</div><span class="detail">Periode {{ $month }}</span></article>
        </div>
        <div class="card" style="margin-top:14px">
            <h3>Aktivitas presensi terbaru · {{ $month }}</h3>
            @forelse ($attendance->take(10) as $record)
                <p><strong>{{ $record->user?->name ?? 'Pengguna' }}</strong> · {{ $record->tanggal }} · masuk {{ $record->jam_masuk }} · keluar {{ $record->jam_pulang ?? 'belum absen keluar' }}</p>
            @empty
                <p class="muted">Belum ada presensi pada periode ini.</p>
            @endforelse
        </div>
    </section>

    <section id="attendance">
        <h2>Presensi admin</h2>
        @php
            $todayAttendance = \App\Models\Presensi::where('user_id', auth()->id())->whereDate('tanggal', today())->first();
        @endphp
        <div class="card">
            <p>Hari ini: {{ today()->format('d-m-Y') }} ·
                @if (!$todayAttendance) belum absen masuk
                @else masuk {{ $todayAttendance->jam_masuk }} · keluar {{ $todayAttendance->jam_pulang ?? 'belum' }}
                @endif
            </p>
            <form method="POST" action="{{ route('admin.attendance', ['action' => 'check-in']) }}" class="inline">
                @csrf<button type="submit" @disabled($todayAttendance)>Absen masuk</button>
            </form>
            <form method="POST" action="{{ route('admin.attendance', ['action' => 'check-out']) }}" class="inline">
                @csrf<button class="secondary" type="submit" @disabled(!$todayAttendance || $todayAttendance->jam_pulang)>Absen keluar</button>
            </form>
        </div>
        <h2>Monitoring presensi · {{ $month }}</h2>
        <div class="scroll" style="margin-top:14px">
            <table><thead><tr><th>Tanggal</th><th>Nama</th><th>Role</th><th>Masuk</th><th>Keluar</th><th>Durasi</th></tr></thead><tbody>
            @forelse ($attendance as $record)
                @php
                    $minutes = 0;
                    if ($record->jam_pulang) {
                        $from = \Carbon\Carbon::parse($record->tanggal.' '.$record->jam_masuk);
                        $to = \Carbon\Carbon::parse($record->tanggal.' '.$record->jam_pulang);
                        if ($to->lessThan($from)) $to->addDay();
                        $minutes = max(0, intdiv($to->timestamp - $from->timestamp, 60));
                    }
                @endphp
                <tr><td>{{ $record->tanggal }}</td><td>{{ $record->user?->name ?? '-' }}</td><td>{{ $record->user?->role ?? '-' }}</td>
                    <td>{{ $record->jam_masuk }}</td><td>{{ $record->jam_pulang ?? '—' }}</td>
                    <td>{{ $record->jam_pulang ? intdiv($minutes, 60).'j '.($minutes % 60).'m' : 'Berjalan' }}</td></tr>
            @empty<tr><td colspan="6" class="muted">Belum ada data presensi periode ini.</td></tr>@endforelse
            </tbody></table>
        </div>
    </section>

    <section id="requests">
        <h2>Pengajuan dan persetujuan</h2>
        <div class="grid">
            <article class="card">
                <h3>Ajukan cuti, izin, sakit, atau lembur</h3>
                <form method="POST" action="{{ route('admin.requests.store') }}" class="stack">
                    @csrf
                    <div class="fields">
                        <select name="type" id="request-type" required>
                            <option value="cuti">Cuti</option><option value="izin">Izin</option><option value="sakit">Sakit</option><option value="lembur">Lembur</option>
                        </select>
                        <input type="date" name="start_date" value="{{ old('start_date', today()->toDateString()) }}" required>
                        <input type="date" name="end_date" value="{{ old('end_date', today()->toDateString()) }}">
                        <input type="time" name="start_time" id="start-time" aria-label="Jam mulai lembur">
                        <input type="time" name="end_time" id="end-time" aria-label="Jam selesai lembur">
                    </div>
                    <textarea name="reason" placeholder="Alasan atau keterangan" required>{{ old('reason') }}</textarea>
                    <button type="submit">Kirim pengajuan</button>
                </form>
            </article>
            <article class="card">
                <h3>Daftar pengajuan · {{ $month }}</h3>
                <p class="muted">Admin tidak dapat menyetujui pengajuannya sendiri.</p>
            </article>
        </div>
        <div class="scroll" style="margin-top:14px">
            <table><thead><tr><th>Pengaju</th><th>Jenis/tanggal</th><th>Alasan</th><th>Status</th><th>Keputusan</th></tr></thead><tbody>
            @forelse ($requests as $item)
                <tr>
                    <td>{{ $item->user?->name ?? '-' }}<small>{{ $item->user?->role ?? '-' }}</small></td>
                    <td>{{ ucfirst($item->type) }}<small>{{ $item->start_date }}{{ $item->end_date && $item->end_date != $item->start_date ? ' — '.$item->end_date : '' }}</small>
                        @if ($item->type === 'lembur')<small>{{ $item->start_time }} — {{ $item->end_time }}</small>@endif
                    </td>
                    <td>{{ $item->reason }}@if($item->reviewer_note)<small>Catatan: {{ $item->reviewer_note }}</small>@endif</td>
                    <td><span class="status {{ $item->status }}">{{ ucfirst($item->status) }}</span></td>
                    <td>
                        @if ($item->status === 'pending' && $item->user_id !== auth()->id())
                            <form method="POST" action="{{ route('admin.requests.decision', $item) }}" class="inline">
                                @csrf @method('PATCH')
                                <input name="reviewer_note" aria-label="Catatan keputusan" placeholder="Catatan (opsional)">
                                <button name="status" value="approved" type="submit">Setujui</button>
                                <button class="danger" name="status" value="rejected" type="submit">Tolak</button>
                            </form>
                        @else
                            <span class="muted">{{ $item->reviewer?->name ?? '—' }}</span>
                        @endif
                    </td>
                </tr>
            @empty<tr><td colspan="5" class="muted">Belum ada pengajuan pada periode ini.</td></tr>@endforelse
            </tbody></table>
        </div>
    </section>

    <section id="reports">
        <h2>Performa & laporan karyawan · {{ $month }}</h2>
        <p class="muted">Indikator dihitung dari presensi dan durasi kerja. Hari kerja dihitung Senin–Jumat (belum memperhitungkan hari libur); ini bukan penilaian produktivitas.</p>
        <div class="scroll"><table>
            <thead><tr><th>Karyawan</th><th>Hari hadir</th><th>Kehadiran</th><th>Total jam kerja</th><th>Rata-rata per hari hadir</th><th>Cuti/izin/sakit disetujui</th><th>Lembur disetujui</th></tr></thead>
            <tbody>
            @forelse ($reports as $report)
                <tr><td>{{ $report['user']->name }}<small>{{ $report['user']->email }}</small></td>
                    <td>{{ $report['attendance_days'] }} / {{ $workDaysInMonth }} hari kerja</td>
                    <td>{{ number_format($report['attendance_rate'], 1) }}%</td>
                    <td>{{ intdiv($report['work_minutes'], 60) }}j {{ $report['work_minutes'] % 60 }}m</td>
                    <td>{{ intdiv($report['average_work_minutes'], 60) }}j {{ $report['average_work_minutes'] % 60 }}m</td>
                    <td>{{ $report['leave_days'] }} hari</td><td>{{ $report['approved_overtime'] }}</td></tr>
            @empty<tr><td colspan="7" class="muted">Belum ada karyawan aktif.</td></tr>@endforelse
            </tbody>
        </table></div>
    </section>

    <section id="users">
        <h2>Kelola akun HRD dan karyawan</h2>
        <article class="card">
            <h3>Tambah akun</h3>
            <form method="POST" action="{{ route('admin.users.store') }}" class="fields">
                @csrf
                <input name="name" placeholder="Nama lengkap" required>
                <input name="email" type="email" placeholder="Email" required>
                <input name="password" type="password" placeholder="Password (min. 8 karakter)" minlength="8" required>
                <select name="role" required><option value="karyawan">Karyawan</option><option value="hrd">HRD</option></select>
                <button type="submit">Tambah pengguna</button>
            </form>
        </article>
        <div class="scroll" style="margin-top:14px"><table>
            <thead><tr><th>Nama / email</th><th>Role</th><th>Status</th><th>Edit akun</th><th>Akses</th></tr></thead>
            <tbody>
            @forelse ($users as $user)
                <tr>
                    <td>{{ $user->name }}<small>{{ $user->email }}</small></td><td>{{ ucfirst($user->role) }}</td>
                    <td>{{ $user->is_active ? 'Aktif' : 'Nonaktif' }}</td>
                    <td>
                        <form method="POST" action="{{ route('admin.users.update', $user) }}" class="inline">
                            @csrf @method('PUT')
                            <input name="name" value="{{ $user->name }}" aria-label="Nama" required>
                            <input name="email" type="email" value="{{ $user->email }}" aria-label="Email" required>
                            <select name="role" aria-label="Role">
                                <option value="karyawan" @selected($user->role === 'karyawan')>Karyawan</option>
                                <option value="hrd" @selected($user->role === 'hrd')>HRD</option>
                            </select>
                            <input name="password" type="password" minlength="8" placeholder="Password baru (opsional)" aria-label="Password baru">
                            <button class="secondary" type="submit">Simpan</button>
                        </form>
                    </td>
                    <td><form method="POST" action="{{ route('admin.users.toggle', $user) }}">
                        @csrf @method('PATCH')
                        <button class="{{ $user->is_active ? 'danger' : '' }}" type="submit">{{ $user->is_active ? 'Nonaktifkan' : 'Aktifkan' }}</button>
                    </form></td>
                </tr>
            @empty<tr><td colspan="5" class="muted">Belum ada akun HRD atau karyawan.</td></tr>@endforelse
            </tbody>
        </table></div>
    </section>

    <section id="profile">
        <h2>Profil admin</h2>
        <article class="card">
            <form method="POST" action="{{ route('admin.profile.update') }}" class="fields">
                @csrf @method('PUT')
                <input name="name" value="{{ auth()->user()->name }}" aria-label="Nama" required>
                <input name="email" type="email" value="{{ auth()->user()->email }}" aria-label="Email" required>
                <input name="password" type="password" minlength="8" placeholder="Password baru (opsional)" aria-label="Password baru">
                <input name="password_confirmation" type="password" minlength="8" placeholder="Konfirmasi password" aria-label="Konfirmasi password">
                <button type="submit">Simpan profil</button>
            </form>
        </article>
    </section>
</main>
</div>
</div>
<script>
    const type = document.getElementById('request-type');
    const startTime = document.getElementById('start-time');
    const endTime = document.getElementById('end-time');
    const updateOvertimeFields = () => {
        const overtime = type.value === 'lembur';
        startTime.required = overtime;
        endTime.required = overtime;
        startTime.disabled = !overtime;
        endTime.disabled = !overtime;
    };
    type.addEventListener('change', updateOvertimeFields);
    updateOvertimeFields();
</script>
</body>
</html>
