import 'package:kostku/features/payment/models/payment_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFExportService {
  // Format currency
  static String formatCurrency(int amount) {
    // Manual format tanpa locale
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  // Format date
  static String formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Get month name
  static String getMonthName(int month) {
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
    return months[month - 1];
  }

  // ==================== LAPORAN KEUANGAN BULANAN ====================
  static Future<void> generateMonthlyFinancialReport({
    required DateTime month,
    required List<Payment> payments,
    required int totalRevenue,
    required double collectionRate,
    required double occupancyRate,
    required int outstandingCount,
    required String kostName,
  }) async {
    final pdf = pw.Document();

    // Calculate summary
    final paidPayments = payments.where((p) => p.isPaid).toList();
    final pendingPayments = payments.where((p) => p.isPending).toList();
    final overduePayments = payments.where((p) => p.isOverdue).toList();

    final totalExpected = payments.fold(0, (sum, p) => sum + p.amount);
    final totalPaid = paidPayments.fold(0, (sum, p) => sum + p.amount);
    final totalOutstanding = totalExpected - totalPaid;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(width: 2, color: PdfColors.blue),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LAPORAN KEUANGAN BULANAN',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  kostName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Periode: ${getMonthName(month.month)} ${month.year}',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Tanggal Cetak: ${formatDate(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Summary Statistics
          pw.Text(
            'RINGKASAN',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Column(
              children: [
                _buildSummaryRow(
                  'Total Kamar Terisi',
                  '${occupancyRate.toStringAsFixed(1)}%',
                ),
                pw.Divider(),
                _buildSummaryRow(
                  'Total Tagihan',
                  formatCurrency(totalExpected),
                ),
                _buildSummaryRow(
                  'Total Terbayar',
                  formatCurrency(totalPaid),
                  color: PdfColors.green,
                ),
                _buildSummaryRow(
                  'Total Tunggakan',
                  formatCurrency(totalOutstanding),
                  color: PdfColors.red,
                ),
                pw.Divider(),
                _buildSummaryRow(
                  'Tingkat Pembayaran',
                  '${collectionRate.toStringAsFixed(1)}%',
                ),
                _buildSummaryRow(
                  'Jumlah Pembayaran',
                  '${payments.length} tagihan',
                ),
                _buildSummaryRow(
                  '   - Lunas',
                  '${paidPayments.length}',
                  color: PdfColors.green,
                ),
                _buildSummaryRow(
                  '   - Pending',
                  '${pendingPayments.length}',
                  color: PdfColors.orange,
                ),
                _buildSummaryRow(
                  '   - Terlambat',
                  '${overduePayments.length}',
                  color: PdfColors.red,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Payment Details Table
          pw.Text(
            'DETAIL PEMBAYARAN',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),

          _buildPaymentTable(payments),

          pw.SizedBox(height: 24),

          // Notes section
          if (overduePayments.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.red300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Icon(
                        const pw.IconData(0xe88e), // warning icon
                        color: PdfColors.red,
                        size: 16,
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'PERHATIAN',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red900,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Terdapat ${overduePayments.length} pembayaran yang terlambat. Harap segera dilakukan penagihan.',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],

          // Footer
          pw.SizedBox(height: 40),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Dokumen ini dibuat secara otomatis oleh sistem KostKu',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    // Print or save PDF
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Laporan_Keuangan_${month.year}_${month.month}.pdf',
    );
  }

  // ==================== LAPORAN PEMBAYARAN TENANT ====================
  static Future<void> generateTenantPaymentReport({
    required String tenantName,
    required String roomNumber,
    required List<Payment> payments,
    required String kostName,
  }) async {
    final pdf = pw.Document();

    final totalPaid = payments
        .where((p) => p.isPaid)
        .fold(0, (sum, p) => sum + p.amount);
    final totalPending = payments
        .where((p) => !p.isPaid)
        .fold(0, (sum, p) => sum + p.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(width: 2, color: PdfColors.blue),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RIWAYAT PEMBAYARAN',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  kostName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Nama: $tenantName',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Kamar: $roomNumber',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Tanggal Cetak: ${formatDate(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _buildSummaryRow(
                  'Total Terbayar',
                  formatCurrency(totalPaid),
                  color: PdfColors.green,
                ),
                _buildSummaryRow(
                  'Total Tunggakan',
                  formatCurrency(totalPending),
                  color: PdfColors.red,
                ),
                pw.Divider(),
                _buildSummaryRow(
                  'Total Pembayaran',
                  '${payments.length} transaksi',
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Payment Table
          _buildPaymentTable(payments),

          // Footer
          pw.SizedBox(height: 40),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Dokumen ini dibuat secara otomatis oleh sistem KostKu',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Riwayat_Pembayaran_${tenantName.replaceAll(' ', '_')}.pdf',
    );
  }

  // ==================== HELPER WIDGETS ====================

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentTable(List<Payment> payments) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Tenant
        1: const pw.FlexColumnWidth(1), // Room
        2: const pw.FlexColumnWidth(2), // Period
        3: const pw.FlexColumnWidth(2), // Amount
        4: const pw.FlexColumnWidth(1.5), // Status
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _buildTableCell('Penyewa', isHeader: true),
            _buildTableCell('Kamar', isHeader: true),
            _buildTableCell('Periode', isHeader: true),
            _buildTableCell('Jumlah', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...payments.map((payment) {
          PdfColor statusColor;
          String statusText;

          switch (payment.status) {
            case PaymentStatus.paid:
              statusColor = PdfColors.green;
              statusText = 'LUNAS';
              break;
            case PaymentStatus.pending:
              statusColor = PdfColors.orange;
              statusText = 'PENDING';
              break;
            case PaymentStatus.overdue:
              statusColor = PdfColors.red;
              statusText = 'TERLAMBAT';
              break;
          }

          return pw.TableRow(
            children: [
              _buildTableCell(payment.tenantName),
              _buildTableCell(payment.roomNumber),
              _buildTableCell(payment.monthString),
              _buildTableCell(formatCurrency(payment.amount)),
              _buildTableCell(statusText, color: statusColor),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}
