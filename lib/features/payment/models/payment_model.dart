enum PaymentStatus { pending, paid, overdue }

class Payment {
  final int? id;
  final int tenantId;
  final String tenantName;
  final String roomNumber;
  final DateTime month;
  final int amount;
  final DateTime? paidDate;
  PaymentStatus status;
  final String? receiptPhoto;
  final String? notes;

  Payment({
    this.id,
    required this.tenantId,
    this.tenantName = '',
    this.roomNumber = '',
    required this.month,
    required this.amount,
    this.paidDate,
    this.status = PaymentStatus.pending,
    this.receiptPhoto,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'month': month.toIso8601String(),
      'amount': amount,
      'paid_date': paidDate?.toIso8601String(),
      'status': status.name,
      'receipt_photo': receiptPhoto,
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      tenantId: map['tenant_id'] as int,
      tenantName: map['tenant_name'] ?? '',
      roomNumber: map['room_number'] ?? '',
      month: DateTime.parse(map['month']),
      amount: map['amount'] as int,
      paidDate: map['paid_date'] != null
          ? DateTime.parse(map['paid_date'])
          : null,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      receiptPhoto: map['receipt_photo'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Payment copyWith({
    int? id,
    int? tenantId,
    String? tenantName,
    String? roomNumber,
    DateTime? month,
    int? amount,
    DateTime? paidDate,
    PaymentStatus? status,
    String? receiptPhoto,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      roomNumber: roomNumber ?? this.roomNumber,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      receiptPhoto: receiptPhoto ?? this.receiptPhoto,
      notes: notes ?? this.notes,
    );
  }

  // Helper getters
  bool get isPaid => status == PaymentStatus.paid;
  bool get isPending => status == PaymentStatus.pending;
  bool get isOverdue => status == PaymentStatus.overdue;

  // Check if payment is overdue
  bool checkOverdue() {
    if (isPaid) return false;

    final now = DateTime.now();

    // Due date: tanggal 5 bulan berikutnya dari payment month
    // Example: Januari 2026 → Due: 5 Februari 2026
    final dueDate = DateTime(month.year, month.month + 1, 5);

    final isOverdue = now.isAfter(dueDate);

    return isOverdue;
  }

  // Get formatted month string
  String get monthString {
    const months = [
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
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  // Get days until due date
  int get daysUntilDue {
    try {
      final now = DateTime.now();

      // Due date calculation:
      // Payment month: Januari 2026 (2026-01-01)
      // Due date: 5 Februari 2026 (2026-02-05)
      final dueDate = DateTime(month.year, month.month + 1, 5);

      // Calculate difference in days
      final difference = dueDate.difference(now).inDays;

      // ✅ DEBUG LOGGING (comment out in production)
      print('📅 PAYMENT ${id ?? 'NEW'} - Days Until Due Calculation:');
      print(
        '   Payment Month: ${month.year}-${month.month.toString().padLeft(2, '0')}-01 (${monthString})',
      );
      print(
        '   Due Date: ${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
      );
      print(
        '   Today: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      );
      print('   Days Until Due: $difference days');
      print(
        '   Status: ${difference < 0
            ? "OVERDUE"
            : difference <= 7
            ? "DUE SOON"
            : "OK"}',
      );

      return difference;
    } catch (e) {
      print('❌ ERROR calculating daysUntilDue: $e');
      print('   Payment ID: $id');
      print('   Month: $month');
      return 0;
    }
  }

  // ✅ Alternative: Get due date as DateTime
  DateTime get dueDate {
    return DateTime(month.year, month.month + 1, 5);
  }

  // ✅ Get formatted due date string
  String get dueDateString {
    final due = dueDate;
    const months = [
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
    ];
    return '${due.day} ${months[due.month - 1]} ${due.year}';
  }
}
