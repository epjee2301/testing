import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AttendancePanel extends StatefulWidget {
  const AttendancePanel({
    super.key,
    required this.api,
    this.showActions = true,
  });

  final ApiService api;
  final bool showActions;

  @override
  State<AttendancePanel> createState() => _AttendancePanelState();
}

class _AttendancePanelState extends State<AttendancePanel> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _todayAttendance;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String get _monthKey =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await widget.api.attendance(_monthKey);
      final now = DateTime.now();
      final currentMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final todayRecords = _monthKey == currentMonth
          ? records
          : await widget.api.attendance(currentMonth);
      final todayKey = _dateKey(now);
      final todayAttendance = todayRecords
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (record) =>
                record?['tanggal']?.toString().startsWith(todayKey) ?? false,
            orElse: () => null,
          );
      if (!mounted) return;
      setState(() {
        _records = records;
        _todayAttendance = todayAttendance;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ApiService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _selectedDayRecords => _records
      .where(
        (record) =>
            record['tanggal']?.toString().startsWith(_dateKey(_selectedDate)) ??
            false,
      )
      .toList();

  Future<void> _record(String action) async {
    setState(() => _saving = true);
    try {
      final result = await widget.api.recordAttendance(action);
      if (!mounted) return;
      _showMessage(
        result['message']?.toString() ?? 'Presensi berhasil disimpan.',
      );
      await _load();
    } catch (error) {
      if (mounted) _showMessage(ApiService.errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _selectedDate = _month;
    });
    _load();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayRecord = _todayAttendance;
    final hasCheckedIn = todayRecord != null;
    final hasCheckedOut =
        todayRecord != null && todayRecord['jam_pulang'] != null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.showActions ? 'Presensi harian' : 'Riwayat presensi',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (widget.showActions) ...[
          const SizedBox(height: 8),
          Text('Catat jam masuk dan pulang. Foto bersifat opsional.'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    hasCheckedOut
                        ? 'Presensi hari ini selesai'
                        : hasCheckedIn
                        ? 'Sudah masuk pukul ${todayRecord['jam_masuk']}'
                        : 'Belum ada presensi hari ini',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (hasCheckedOut)
                    Text('Pulang pukul ${todayRecord['jam_pulang']}'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: _saving || hasCheckedIn
                            ? null
                            : () => _record('check-in'),
                        icon: const Icon(Icons.login),
                        label: const Text('Absen masuk'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _saving || !hasCheckedIn || hasCheckedOut
                            ? null
                            : () => _record('check-out'),
                        icon: const Icon(Icons.logout),
                        label: const Text('Absen keluar'),
                      ),
                      if (_saving)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text(
                  '${_monthName(_month.month)} ${_month.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                leading: IconButton(
                  tooltip: 'Bulan sebelumnya',
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                trailing: IconButton(
                  tooltip: 'Bulan berikutnya',
                  onPressed:
                      _month.year == DateTime.now().year &&
                          _month.month == DateTime.now().month
                      ? null
                      : () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
              CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2015),
                lastDate: DateTime.now(),
                currentDate: DateTime.now(),
                onDisplayedMonthChanged: (date) {
                  _month = DateTime(date.year, date.month);
                  _load();
                },
                onDateChanged: (date) => setState(() => _selectedDate = date),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Riwayat ${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          _ErrorCard(message: _error!, onRetry: _load)
        else if (_selectedDayRecords.isEmpty)
          const Card(
            child: ListTile(
              title: Text('Tidak ada presensi pada tanggal ini.'),
            ),
          )
        else
          ..._selectedDayRecords.map(_attendanceCard),
      ],
    );
  }

  Widget _attendanceCard(Map<String, dynamic> record) {
    final minutes = _workedMinutes(record);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.access_time)),
        title: Text(
          'Masuk ${record['jam_masuk'] ?? '-'}  ·  Keluar ${record['jam_pulang'] ?? '-'}',
        ),
        subtitle: Text(
          record['jam_pulang'] == null
              ? 'Jam kerja sedang berjalan'
              : 'Total kerja ${minutes ~/ 60} jam ${minutes % 60} menit',
        ),
      ),
    );
  }
}

class RequestsPanel extends StatefulWidget {
  const RequestsPanel({
    super.key,
    required this.api,
    this.canReview = false,
    this.onChanged,
    this.initialRequestType,
    this.requestLaunchId = 0,
  });

  final ApiService api;
  final bool canReview;
  final Future<void> Function()? onChanged;
  final String? initialRequestType;
  final int requestLaunchId;

  @override
  State<RequestsPanel> createState() => _RequestsPanelState();
}

class _RequestsPanelState extends State<RequestsPanel> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;
  String? _savingRequestId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RequestsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestLaunchId != oldWidget.requestLaunchId &&
        widget.requestLaunchId > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRequestForm(widget.initialRequestType);
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await widget.api.requests();
      if (mounted) setState(() => _requests = requests);
    } catch (error) {
      if (mounted) setState(() => _error = ApiService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showRequestForm([String? initialType]) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RequestForm(initialType: initialType),
    );
    if (data == null) return;
    try {
      final result = await widget.api.submitRequest(data);
      if (!mounted) return;
      _message(result['message']?.toString() ?? 'Pengajuan terkirim.');
      await _load();
    } catch (error) {
      if (mounted) _message(ApiService.errorMessage(error), isError: true);
    }
  }

  Future<void> _decideRequest(Map<String, dynamic> item, String status) async {
    final noteController = TextEditingController();
    final decision = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == 'approved' ? 'Setujui pengajuan?' : 'Tolak pengajuan?',
        ),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Catatan untuk karyawan (opsional)',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'status': status,
              'reviewer_note': noteController.text.trim(),
            }),
            child: Text(status == 'approved' ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (decision == null) return;

    final requestId = item['id']?.toString();
    if (requestId == null) {
      _message('ID pengajuan tidak tersedia.', isError: true);
      return;
    }

    setState(() => _savingRequestId = requestId);
    try {
      final result = await widget.api.decideRequest(requestId, decision);
      if (!mounted) return;
      _message(result['message']?.toString() ?? 'Keputusan tersimpan.');
      await _load();
      await widget.onChanged?.call();
    } catch (error) {
      if (mounted) _message(ApiService.errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _savingRequestId = null);
    }
  }

  void _message(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              widget.canReview ? 'Pengajuan karyawan' : 'Pengajuan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (!widget.canReview)
              FilledButton.icon(
                onPressed: _showRequestForm,
                icon: const Icon(Icons.add),
                label: const Text('Ajukan'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.canReview
              ? 'Tinjau dan berikan keputusan untuk pengajuan karyawan.'
              : 'Ajukan cuti, izin, sakit, atau lembur.',
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          _ErrorCard(message: _error!, onRetry: _load)
        else if (_requests.isEmpty)
          Card(
            child: ListTile(
              title: Text(
                widget.canReview
                    ? 'Belum ada pengajuan karyawan.'
                    : 'Belum ada pengajuan.',
              ),
            ),
          )
        else
          ..._requests.map((item) => _requestCard(item)),
      ],
    );
  }

  Widget _requestCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'pending';
    final requestId = item['id']?.toString();
    final employee = item['user'];
    final isPending = status == 'pending';
    final isSaving = requestId != null && requestId == _savingRequestId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            ListTile(
              leading: Icon(_requestIcon(item['type']?.toString() ?? '')),
              title: Text(
                '${_capitalize(item['type']?.toString() ?? 'Pengajuan')} · ${_requestStatusLabel(status)}',
              ),
              subtitle: Text(
                [
                  if (widget.canReview && employee is Map)
                    '${employee['name'] ?? 'Karyawan'} · ${employee['email'] ?? ''}',
                  '${item['start_date'] ?? '-'}${item['end_date'] == null || item['end_date'] == item['start_date'] ? '' : ' — ${item['end_date']}'}',
                  item['reason']?.toString() ?? '',
                  if (item['reviewer_note'] != null)
                    'Catatan: ${item['reviewer_note']}',
                ].where((part) => part.isNotEmpty).join('\n'),
              ),
              isThreeLine: true,
            ),
            if (widget.canReview && isPending)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSaving
                          ? null
                          : () => _decideRequest(item, 'rejected'),
                      child: const Text('Tolak'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: isSaving
                          ? null
                          : () => _decideRequest(item, 'approved'),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Setujui'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _requestStatusLabel(String status) => switch (status) {
    'pending' => 'Menunggu',
    'approved' => 'Disetujui',
    'rejected' => 'Ditolak',
    _ => status,
  };
}

class EmployeeRequestsPanel extends StatefulWidget {
  const EmployeeRequestsPanel({
    super.key,
    required this.api,
    this.initialRequestType = 'cuti',
    this.requestLaunchId = 0,
  });

  final ApiService api;
  final String initialRequestType;
  final int requestLaunchId;

  @override
  State<EmployeeRequestsPanel> createState() => _EmployeeRequestsPanelState();
}

class _EmployeeRequestsPanelState extends State<EmployeeRequestsPanel> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );
  String _type = 'cuti';
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  static const _requestTypes = {'cuti', 'izin', 'sakit', 'lembur'};

  @override
  void initState() {
    super.initState();
    _type = _requestTypes.contains(widget.initialRequestType)
        ? widget.initialRequestType
        : 'cuti';
    _load();
  }

  @override
  void didUpdateWidget(covariant EmployeeRequestsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestLaunchId != oldWidget.requestLaunchId &&
        widget.requestLaunchId > 0) {
      setState(() {
        _type = _requestTypes.contains(widget.initialRequestType)
            ? widget.initialRequestType
            : 'cuti';
      });
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.profile(),
        widget.api.requests(),
      ]);
      if (!mounted) return;
      final requests = results[1] as List<Map<String, dynamic>>;
      setState(() {
        _profile = results[0] as Map<String, dynamic>;
        _requests = requests;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ApiService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
      helpText: 'Pilih rentang tanggal',
      saveText: 'Pilih',
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final result = await widget.api.submitRequest({
        'type': _type,
        'start_date': _date(_dateRange.start),
        'end_date': _date(_dateRange.end),
        'reason': _reason.text.trim(),
      });
      if (!mounted) return;
      _reason.clear();
      _message(result['message']?.toString() ?? 'Pengajuan berhasil dikirim.');
      await _load();
    } catch (error) {
      if (mounted) _message(ApiService.errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latestRequest = _requests.isEmpty ? null : _requests.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(17, 14, 17, 24),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 29,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat pagi, ${_profile['name'] ?? 'Karyawan'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1769FF),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Karyawan',
                    style: TextStyle(color: Color(0xFF7C8798), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 27),
        const Text(
          'Buat Pengajuan',
          style: TextStyle(
            color: Color(0xFF151D2D),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E5EB)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _RequestFieldLabel('Jenis Pengajuan'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: _requestInputDecoration(),
                  items: const [
                    DropdownMenuItem(
                      value: 'cuti',
                      child: Text('Cuti Tahunan'),
                    ),
                    DropdownMenuItem(value: 'izin', child: Text('Izin')),
                    DropdownMenuItem(value: 'sakit', child: Text('Izin Sakit')),
                    DropdownMenuItem(value: 'lembur', child: Text('Lembur')),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _type = value ?? 'cuti'),
                ),
                const SizedBox(height: 13),
                const _RequestFieldLabel('Rentang Tanggal'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _submitting ? null : _chooseDateRange,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: _requestInputDecoration(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_displayDate(_dateRange.start)} - ${_displayDate(_dateRange.end)}',
                            style: const TextStyle(
                              color: Color(0xFF293548),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Color(0xFF697789),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                const _RequestFieldLabel('Keterangan / Alasan'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _reason,
                  minLines: 3,
                  maxLines: 4,
                  decoration: _requestInputDecoration(
                    hintText: 'Tuliskan keterangan atau alasan...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Alasan harus diisi.'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _load,
                      child: const Text('Coba lagi'),
                    ),
                  ),
                ],
                const SizedBox(height: 13),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2862E9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Kirim Pengajuan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Status Terakhir',
          style: TextStyle(
            color: Color(0xFF151D2D),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (_loading && latestRequest == null)
          const Center(child: CircularProgressIndicator())
        else if (latestRequest != null)
          _EmployeeLatestRequestCard(request: latestRequest)
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E5EB)),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Text(
              'Belum ada pengajuan.',
              style: TextStyle(color: Color(0xFF778397), fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _RequestFieldLabel extends StatelessWidget {
  const _RequestFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF3B4659),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _EmployeeLatestRequestCard extends StatelessWidget {
  const _EmployeeLatestRequestCard({required this.request});

  final Map<String, dynamic> request;

  @override
  Widget build(BuildContext context) {
    final status = request['status']?.toString() ?? 'pending';
    final statusColor = switch (status) {
      'approved' => const Color(0xFF08765B),
      'rejected' => const Color(0xFFB42318),
      _ => const Color(0xFF9A6700),
    };
    final statusBackground = switch (status) {
      'approved' => const Color(0xFFD4F7E8),
      'rejected' => const Color(0xFFFFE4E1),
      _ => const Color(0xFFFFF1CC),
    };
    final startDate = request['start_date']?.toString() ?? '-';
    final endDate = request['end_date']?.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E5EB)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _requestTypeLabel(request['type']?.toString() ?? ''),
                  style: const TextStyle(
                    color: Color(0xFF293548),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  endDate == null || endDate == startDate
                      ? startDate
                      : '$startDate - $endDate',
                  style: const TextStyle(
                    color: Color(0xFF8792A2),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _requestStatusLabel(status),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _requestInputDecoration({
  String? hintText,
  bool alignLabelWithHint = false,
}) => InputDecoration(
  hintText: hintText,
  alignLabelWithHint: alignLabelWithHint,
  filled: true,
  fillColor: const Color(0xFFF9FAFB),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Color(0xFFD7DDE5)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Color(0xFFD7DDE5)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Color(0xFF2862E9)),
  ),
);

String _requestTypeLabel(String type) => switch (type) {
  'cuti' => 'Cuti Tahunan',
  'izin' => 'Izin',
  'sakit' => 'Izin Sakit',
  'lembur' => 'Lembur',
  _ => 'Pengajuan',
};

String _requestStatusLabel(String status) => switch (status) {
  'approved' => 'Disetujui',
  'rejected' => 'Ditolak',
  _ => 'Menunggu',
};

class ProfilePanel extends StatefulWidget {
  const ProfilePanel({super.key, required this.api});

  final ApiService api;

  @override
  State<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<ProfilePanel> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String _role = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await widget.api.profile();
      if (!mounted) return;
      _name.text = profile['name']?.toString() ?? '';
      _email.text = profile['email']?.toString() ?? '';
      _role = profile['role']?.toString() ?? '';
    } catch (error) {
      if (mounted) _message(ApiService.errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final result = await widget.api.updateProfile({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        if (_password.text.isNotEmpty) ...{
          'password': _password.text,
          'password_confirmation': _confirmation.text,
        },
      });
      if (!mounted) return;
      _password.clear();
      _confirmation.clear();
      _message(result['message']?.toString() ?? 'Profil diperbarui.');
    } catch (error) {
      if (mounted) _message(ApiService.errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Profil saya', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nama harus diisi.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Masukkan email yang valid.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Role'),
                    child: Text(_role),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password baru (opsional)',
                    ),
                    validator: (value) =>
                        value != null && value.isNotEmpty && value.length < 8
                        ? 'Password minimal 8 karakter.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmation,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi password',
                    ),
                    validator: (value) =>
                        _password.text.isNotEmpty && value != _password.text
                        ? 'Konfirmasi password tidak sama.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Menyimpan...' : 'Simpan profil'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestForm extends StatefulWidget {
  const _RequestForm({this.initialType});

  final String? initialType;

  @override
  State<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<_RequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String _type = 'cuti';
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    const requestTypes = {'cuti', 'izin', 'sakit', 'lembur'};
    if (requestTypes.contains(widget.initialType)) {
      _type = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _chooseDate({required bool end}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: end ? _end : _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      if (end) {
        _end = picked;
      } else {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      }
    });
  }

  Future<void> _chooseTime({required bool end}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: end ? _endTime : _startTime,
    );
    if (picked == null) return;
    setState(() {
      if (end) {
        _endTime = picked;
      } else {
        _startTime = picked;
      }
    });
  }

  String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _time(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_type == 'lembur' &&
        (_endTime.hour * 60 + _endTime.minute) <=
            (_startTime.hour * 60 + _startTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam selesai lembur harus setelah jam mulai.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop({
      'type': _type,
      'start_date': _date(_start),
      'end_date': _date(_end),
      if (_type == 'lembur') ...{
        'start_time': _time(_startTime),
        'end_time': _time(_endTime),
      },
      'reason': _reason.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buat pengajuan'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Jenis'),
                  items: const [
                    DropdownMenuItem(value: 'cuti', child: Text('Cuti')),
                    DropdownMenuItem(value: 'izin', child: Text('Izin')),
                    DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                    DropdownMenuItem(value: 'lembur', child: Text('Lembur')),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? 'cuti'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_type == 'lembur' ? 'Tanggal' : 'Tanggal mulai'),
                  subtitle: Text(_date(_start)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () => _chooseDate(end: false),
                ),
                if (_type != 'lembur')
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tanggal selesai'),
                    subtitle: Text(_date(_end)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () => _chooseDate(end: true),
                  ),
                if (_type == 'lembur') ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Jam mulai'),
                    subtitle: Text(_time(_startTime)),
                    onTap: () => _chooseTime(end: false),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Jam selesai'),
                    subtitle: Text(_time(_endTime)),
                    onTap: () => _chooseTime(end: true),
                  ),
                ],
                TextFormField(
                  controller: _reason,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Alasan / keterangan',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Alasan harus diisi.'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Kirim')),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.error_outline, color: Colors.red),
      title: Text(message),
      trailing: IconButton(
        tooltip: 'Coba lagi',
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
      ),
    ),
  );
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _monthName(int month) => const [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
][month - 1];

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

IconData _requestIcon(String type) => switch (type) {
  'cuti' => Icons.beach_access,
  'izin' => Icons.event_available,
  'sakit' => Icons.medical_services_outlined,
  'lembur' => Icons.more_time,
  _ => Icons.event_note,
};

int _workedMinutes(Map<String, dynamic> record) {
  final checkIn = record['jam_masuk']?.toString();
  final checkOut = record['jam_pulang']?.toString();
  if (checkIn == null || checkOut == null) return 0;
  final start = _timeMinutes(checkIn);
  final end = _timeMinutes(checkOut);
  return end >= start ? end - start : 0;
}

int _timeMinutes(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}
