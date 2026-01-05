enum PaymentStatus { pending, paid, overdue }

class Payment {
  final int? id;
  final int tenantId;
  final String tenantName; // Untuk display
  final String roomNumber; // Untuk display
  final DateTime
  month; // Bulan pembayaran (contoh: 2025-01-01 untuk Januari 2025)
  final int amount; // Jumlah yang harus dibayar
  final DateTime? paidDate; // Tanggal pembayaran aktual
  PaymentStatus status;
  final String? receiptPhoto; // Path foto struk pembayaran
  final String? notes; // Catatan tambahan

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

    // Jika belum dibayar dan tanggal sekarang sudah lewat bulan pembayaran
    final now = DateTime.now();
    final dueDate = DateTime(
      month.year,
      month.month + 1,
      5,
    ); // Jatuh tempo tanggal 5 bulan berikutnya

    return now.isAfter(dueDate);
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
    final now = DateTime.now();
    final dueDate = DateTime(month.year, month.month + 1, 5);
    return dueDate.difference(now).inDays;
  }
}
