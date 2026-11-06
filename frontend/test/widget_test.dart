import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/employee_dashboard.dart';
import 'package:frontend/screens/dashboard_components.dart';
import 'package:frontend/screens/hrd_dashboard.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/api_service.dart';

void main() {
  test('API base URL normalization removes trailing slashes', () {
    final api = ApiService();

    api.setBaseUrl('http://localhost:8000/');
    expect(api.baseUrl, 'http://localhost:8000/api');

    api.setBaseUrl('http://localhost:8000/api/');
    expect(api.baseUrl, 'http://localhost:8000/api');
  });

  testWidgets('login screen loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('LookIn Presensi'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('HRD home displays live dashboard summary values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HrdHomePanel(
            profile: const {'name': 'HRD Test'},
            dashboard: const {
              'summary': {
                'employee_count': 75,
                'present_count': 58,
                'attendance_rate': 77,
                'active_cuti_count': 7,
                'active_sakit_count': 3,
                'pending_request_count': 5,
              },
              'notifications': [
                {
                  'type': 'sakit',
                  'status': 'pending',
                  'user': {'name': 'Nadia'},
                  'created_at': '2026-10-31T12:00:00Z',
                },
              ],
            },
            onRefresh: () async {},
            onSeeRequests: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('HRD Test'), findsOneWidget);
    expect(find.text('Total karyawan'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);
    expect(find.text('58'), findsOneWidget);
    expect(find.text('77% karyawan sudah hadir'), findsOneWidget);
    expect(find.text('Notifikasi terbaru'), findsOneWidget);
    expect(find.text('Nadia mengajukan izin sakit'), findsOneWidget);
  });

  testWidgets('HRD dashboard loads and displays backend overview and reports', (
    WidgetTester tester,
  ) async {
    final api = _HrdDashboardApiStub();

    await tester.pumpWidget(MaterialApp(home: HrdDashboard(api: api)));
    await tester.pumpAndSettle();

    expect(api.profileRequests, 2);
    expect(api.dashboardRequests, 1);
    expect(find.textContaining('HRD Integrasi'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);

    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Presensi tercatat'), findsOneWidget);
    expect(find.textContaining('42'), findsOneWidget);

    await tester.tap(find.text('Persetujuan'));
    await tester.pumpAndSettle();
    expect(find.text('Persetujuan'), findsWidgets);
    expect(find.text('Nadia Putri'), findsOneWidget);
    await tester.tap(find.text('Setujui').last);
    await tester.pumpAndSettle();
    expect(find.text('Setujui pengajuan?'), findsOneWidget);
    await tester.tap(find.text('Setujui').last);
    await tester.pumpAndSettle();
    expect(api.requestDecision?['status'], 'approved');
  });

  testWidgets('employee history shows selected day attendance and duration', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EmployeeHistoryPanel(api: _HistoryApiStub())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Papoi'), findsOneWidget);
    expect(find.text('Jam Masuk'), findsOneWidget);
    await tester.ensureVisible(find.text('11j 10m'));
    expect(find.text('06:50 AM'), findsOneWidget);
    expect(find.text('06:00 PM'), findsOneWidget);
    expect(find.text('11j 10m'), findsOneWidget);
  });

  testWidgets('employee history can select a different month and year', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _HistoryApiStub();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EmployeeHistoryPanel(api: api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('${DateTime.now().year}'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih bulan dan tahun'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().year - 1}').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Januari').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();

    expect(find.text('Jan ${DateTime.now().year - 1}'), findsOneWidget);
    expect(api.requestedMonths.last, '${DateTime.now().year - 1}-01');
  });

  testWidgets('employee can submit a request and see its latest status', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _RequestsApiStub();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EmployeeRequestsPanel(api: api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buat Pengajuan'), findsOneWidget);
    expect(find.text('Cuti Tahunan'), findsOneWidget);
    expect(find.text('Status Terakhir'), findsOneWidget);
    expect(find.text('Izin Sakit'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tuliskan keterangan atau alasan...'),
      'Keperluan keluarga',
    );
    await tester.ensureVisible(find.text('Kirim Pengajuan'));
    await tester.tap(find.text('Kirim Pengajuan'));
    await tester.pumpAndSettle();

    expect(api.submittedRequest?['type'], 'cuti');
    expect(api.submittedRequest?['reason'], 'Keperluan keluarga');
    expect(find.text('Pengajuan berhasil dikirim.'), findsOneWidget);
  });

  testWidgets('employee can clock in and out without capturing a photo', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _AttendanceApiStub();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeeHomePanel(api: api, onRequest: (_) {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    await tester.tap(find.text('Clock In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    expect(api.actions, ['check-in']);

    await tester.tap(find.text('Clock Out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    expect(api.actions, ['check-in', 'check-out']);
  });

  testWidgets('employee dashboard uses the four role-specific screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: EmployeeDashboard(api: _EmployeeDashboardApiStub())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('LookIn'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pump();
    expect(find.textContaining('${DateTime.now().year}'), findsWidgets);

    await tester.tap(find.text('Pengajuan'));
    await tester.pump();
    expect(find.text('Buat Pengajuan'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Papoi'), findsOneWidget);
    expect(find.text('Edit Profil'), findsOneWidget);
  });
}

class _EmployeeDashboardApiStub extends ApiService {
  @override
  Future<Map<String, dynamic>> profile() async => {
    'name': 'Papoi',
    'email': 'papoi@example.com',
    'role': 'karyawan',
  };

  @override
  Future<List<Map<String, dynamic>>> attendance(String month) async => [];

  @override
  Future<List<Map<String, dynamic>>> requests() async => [];

  @override
  Future<Map<String, dynamic>> recordAttendance(String action) async => {};
}

class _HrdDashboardApiStub extends ApiService {
  int profileRequests = 0;
  int dashboardRequests = 0;
  Map<String, dynamic>? requestDecision;

  @override
  Future<Map<String, dynamic>> profile() async {
    profileRequests++;
    return {'name': 'HRD Integrasi'};
  }

  @override
  Future<Map<String, dynamic>> hrdDashboard({
    String? month,
    String? date,
  }) async {
    dashboardRequests++;
    return {
      'summary': {
        'employee_count': 13,
        'present_count': 9,
        'attendance_rate': 69,
        'active_cuti_count': 2,
        'active_sakit_count': 1,
        'pending_request_count': 3,
        'monthly_attendance_count': 42,
        'monthly_request_count': 5,
      },
      'notifications': [],
      'weekly_attendance': [
        {'week': 'M1', 'count': 12},
        {'week': 'M2', 'count': 30},
      ],
      'employee_statuses': [
        {
          'id': 1,
          'name': 'Nadia Putri',
          'email': 'nadia@example.com',
          'status': 'hadir',
          'jam_masuk': '08:00:00',
        },
      ],
      'month':
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> attendance(String month) async => [];

  @override
  Future<List<Map<String, dynamic>>> requests() async => [
    {
      'id': 12,
      'type': 'sakit',
      'status': requestDecision?['status'] ?? 'pending',
      'start_date': '2026-10-12',
      'end_date': '2026-10-13',
      'reason': 'Demam, diminta dokter beristirahat.',
      'created_at': '2026-10-11T07:45:00Z',
      'user': {'name': 'Nadia Putri', 'email': 'nadia@example.com'},
    },
  ];

  @override
  Future<Map<String, dynamic>> decideRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    requestDecision = data;
    return {'message': 'Keputusan tersimpan.'};
  }
}

class _HistoryApiStub extends ApiService {
  final List<String> requestedMonths = [];

  @override
  Future<Map<String, dynamic>> profile() async => {'name': 'Papoi'};

  @override
  Future<List<Map<String, dynamic>>> attendance(String month) async {
    requestedMonths.add(month);
    final today = DateTime.now();
    return [
      {
        'tanggal':
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
        'jam_masuk': '06:50:00',
        'jam_pulang': '18:00:00',
      },
    ];
  }
}

class _RequestsApiStub extends ApiService {
  Map<String, dynamic>? submittedRequest;

  @override
  Future<Map<String, dynamic>> profile() async => {'name': 'Papoi'};

  @override
  Future<List<Map<String, dynamic>>> requests() async => [
    {
      'type': 'sakit',
      'status': 'approved',
      'start_date': '2026-09-15',
      'end_date': '2026-09-15',
    },
  ];

  @override
  Future<Map<String, dynamic>> submitRequest(Map<String, dynamic> data) async {
    submittedRequest = data;
    return {'message': 'Pengajuan berhasil dikirim.'};
  }
}

class _AttendanceApiStub extends ApiService {
  final List<String> actions = [];
  Map<String, dynamic>? todayAttendance;

  @override
  Future<Map<String, dynamic>> profile() async => {'name': 'Papoi'};

  @override
  Future<List<Map<String, dynamic>>> attendance(String month) async =>
      todayAttendance == null ? [] : [todayAttendance!];

  @override
  Future<Map<String, dynamic>> recordAttendance(String action) async {
    actions.add(action);
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (action == 'check-in') {
      todayAttendance = {
        'tanggal': today,
        'jam_masuk': '08:00:00',
        'jam_pulang': null,
      };
    } else {
      todayAttendance = {...?todayAttendance, 'jam_pulang': '17:00:00'};
    }
    return {
      'message': action == 'check-in'
          ? 'Check In berhasil'
          : 'Check Out berhasil',
    };
  }
}
