import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../tenant/providers/tenant_provider.dart';
import '../../tenant/models/tenant_model.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';

class PaymentFormPage extends StatefulWidget {
  final Payment? payment;

  const PaymentFormPage({super.key, this.payment});

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends State<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedTenantId;
  DateTime? _selectedMonth;
  PaymentStatus _selectedStatus = PaymentStatus.pending;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<TenantProvider>().fetchTenants();
    });

    if (widget.payment != null) {
      final p = widget.payment!;
      _selectedTenantId = p.tenantId;
      _selectedMonth = p.month;
      _amountController.text = p.amount.toString();
      _notesController.text = p.notes ?? '';
      _selectedStatus = p.status;
    } else {
      _selectedMonth = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tenant terlebih dahulu')),
      );
      return;
    }
    if (_selectedMonth == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih bulan pembayaran')));
      return;
    }

    try {
      final payment = Payment(
        id: widget.payment?.id,
        tenantId: _selectedTenantId!,
        month: _selectedMonth!,
        amount: int.parse(_amountController.text),
        status: _selectedStatus,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (widget.payment == null) {
        await context.read<PaymentProvider>().addPayment(payment);
      } else {
        await context.read<PaymentProvider>().updatePayment(payment);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.payment == null
                  ? 'Pembayaran berhasil ditambahkan'
                  : 'Pembayaran berhasil diupdate',
            ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.payment == null ? 'Tambah Pembayaran' : 'Edit Pembayaran',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tenant Selection
            Consumer<TenantProvider>(
              builder: (context, tenantProvider, _) {
                final activeTenants = tenantProvider.tenants
                    .where((t) => t.roomId != null)
                    .toList();

                return DropdownButtonFormField<int>(
                  value: _selectedTenantId,
                  decoration: const InputDecoration(
                    labelText: 'Tenant',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  items: activeTenants.map((tenant) {
                    return DropdownMenuItem(
                      value: tenant.id,
                      child: Text('${tenant.name} - Kamar ${tenant.roomId}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTenantId = value;

                      // Auto-fill amount dari room price
                      if (value != null) {
                        final tenant = activeTenants.firstWhere(
                          (t) => t.id == value,
                        );
                        // Get room price - you might need to fetch this
                        // For now, leave empty to let user input
                      }
                    });
                  },
                  validator: (value) => value == null ? 'Pilih tenant' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Month Selection
            InkWell(
              onTap: _selectMonth,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Bulan Pembayaran',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedMonth != null
                      ? _getMonthString(_selectedMonth!)
                      : 'Pilih Bulan',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah tidak boleh kosong';
                }
                if (int.tryParse(value) == null) {
                  return 'Masukkan angka yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<PaymentStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.info),
                border: OutlineInputBorder(),
              ),
              items: PaymentStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(
                  widget.payment == null
                      ? 'Tambah Pembayaran'
                      : 'Update Pembayaran',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthString(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }
}
