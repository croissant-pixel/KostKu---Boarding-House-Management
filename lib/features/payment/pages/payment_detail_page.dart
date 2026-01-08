import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';

class PaymentDetailPage extends StatefulWidget {
  final Payment payment;

  const PaymentDetailPage({super.key, required this.payment});

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _markAsPaid() async {
    final paidDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: widget.payment.month,
      lastDate: DateTime.now(),
    );

    if (paidDate == null) return;

    // Ask if user wants to upload receipt
    final uploadReceipt = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upload Bukti Pembayaran'),
        content: const Text('Apakah Anda ingin upload foto struk pembayaran?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    String? receiptPhoto;

    if (uploadReceipt == true) {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        receiptPhoto = image.path;
      }
    }

    try {
      await context.read<PaymentProvider>().markAsPaid(
        paymentId: widget.payment.id!,
        paidDate: paidDate,
        receiptPhoto: receiptPhoto,
      );

      if (mounted) {
        Navigator.pop(context); // Close detail page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil ditandai lunas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePayment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pembayaran'),
        content: const Text('Yakin ingin menghapus data pembayaran ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<PaymentProvider>().deletePayment(widget.payment.id!);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final provider = context.watch<PaymentProvider>();

    Color statusColor;
    IconData statusIcon;

    switch (payment.status) {
      case PaymentStatus.paid:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case PaymentStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case PaymentStatus.overdue:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
        actions: [
          if (!payment.isPaid)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePayment,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Card(
            color: statusColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: statusColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(statusIcon, size: 60, color: statusColor),
                  const SizedBox(height: 12),
                  Text(
                    payment.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tenant Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi Penyewa',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.person, 'Nama', payment.tenantName),
                  _buildInfoRow(Icons.room, 'Kamar', payment.roomNumber),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Payment Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi Pembayaran',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Periode',
                    payment.monthString,
                  ),
                  _buildInfoRow(
                    Icons.attach_money,
                    'Jumlah',
                    provider.formatCurrency(payment.amount),
                  ),
                  if (payment.isPaid && payment.paidDate != null)
                    _buildInfoRow(
                      Icons.check,
                      'Tanggal Bayar',
                      payment.paidDate!.toLocal().toString().split(' ')[0],
                    ),
                  if (payment.notes != null && payment.notes!.isNotEmpty)
                    _buildInfoRow(Icons.note, 'Catatan', payment.notes!),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          

          // Due date info for pending/overdue
          if (!payment.isPaid) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: payment.isOverdue
                    ? Colors.red.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: payment.isOverdue ? Colors.red : Colors.orange,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    payment.isOverdue ? Icons.warning : Icons.timer,
                    color: payment.isOverdue ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      payment.isOverdue
                          ? 'Pembayaran terlambat ${payment.daysUntilDue} hari!'
                          : 'Jatuh tempo ${payment.daysUntilDue} hari lagi',
                      style: TextStyle(
                        color: payment.isOverdue ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Receipt Photo
          if (payment.receiptPhoto != null &&
              payment.receiptPhoto!.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Bukti Pembayaran',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(payment.receiptPhoto!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Mark as Paid Button
          if (!payment.isPaid) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Tandai Lunas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _markAsPaid,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
