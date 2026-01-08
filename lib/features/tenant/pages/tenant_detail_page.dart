import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kostku/core/services/url_launcher_service.dart';
import 'package:provider/provider.dart';
import '../../property/models/room_model.dart';
import '../../property/providers/room_provider.dart';
import '../models/tenant_model.dart';
import '../providers/tenant_provider.dart';

class TenantDetailPage extends StatefulWidget {
  final Tenant tenant;
  const TenantDetailPage({super.key, required this.tenant});

  @override
  State<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends State<TenantDetailPage> {
  Room? tenantRoom;

  @override
  void initState() {
    super.initState();
    final rooms = context.read<RoomProvider>().rooms;
    try {
      tenantRoom = rooms.firstWhere((r) => r.id == widget.tenant.roomId);
    } catch (e) {
      tenantRoom = null;
    }
  }

  DateTime? getContractEndDate(Tenant tenant) {
    return tenant.checkOutDate;
  }

  int getRemainingDays(DateTime endDate) {
    return endDate.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final tenant = widget.tenant;
    final isCheckedIn = tenant.checkInDate != null;
    final endDate = getContractEndDate(tenant);
    final remainingDays = endDate != null ? getRemainingDays(endDate) : null;

    Color? contractColor;
    String? contractText;
    IconData? contractIcon;

    if (remainingDays != null) {
      if (remainingDays <= 0) {
        contractColor = Colors.red;
        contractText = 'Kontrak sudah habis';
        contractIcon = Icons.warning;
      } else if (remainingDays <= 7) {
        contractColor = Colors.orange;
        contractText = 'Kontrak habis dalam $remainingDays hari';
        contractIcon = Icons.timer;
      } else {
        contractColor = Colors.green;
        contractText = 'Kontrak aktif ($remainingDays hari tersisa)';
        contractIcon = Icons.check_circle;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // App Bar dengan foto profile besar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.blue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade700, Colors.blue.shade400],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Hero(
                      tag: 'tenant-${tenant.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: tenant.profilePhoto != null
                              ? FileImage(File(tenant.profilePhoto!))
                              : null,
                          child: tenant.profilePhoto == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.blue,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tenant.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tenantRoom != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Kamar ${tenantRoom!.number}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.phone,
                          label: 'Telepon',
                          color: Colors.green,
                          onTap: () async {
                            await UrlLauncherService.makePhoneCall(
                              context,
                              tenant.phone,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.message,
                          label: 'WhatsApp',
                          color: Colors.teal,
                          onTap: () async {
                            // TODO: Implement WhatsApp
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fitur WhatsApp belum tersedia'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Contract Status (if checked in)
                  if (isCheckedIn && contractText != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: contractColor!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: contractColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: contractColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              contractIcon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Kontrak',
                                  style: TextStyle(
                                    color: contractColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contractText,
                                  style: TextStyle(
                                    color: contractColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Personal Info Card
                  _buildInfoCard(
                    title: 'Informasi Personal',
                    icon: Icons.person,
                    children: [
                      _buildInfoTile(
                        icon: Icons.badge,
                        label: 'Nama Lengkap',
                        value: tenant.name,
                      ),
                      _buildInfoTile(
                        icon: Icons.phone_android,
                        label: 'Nomor HP',
                        value: tenant.phone,
                      ),
                      _buildInfoTile(
                        icon: Icons.email,
                        label: 'Email',
                        value: tenant.email,
                      ),
                      if (tenant.emergencyContact != null &&
                          tenant.emergencyContact!.isNotEmpty)
                        _buildInfoTile(
                          icon: Icons.contact_emergency,
                          label: 'Kontak Darurat',
                          value: tenant.emergencyContact!,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Room Info Card (if assigned)
                  if (tenantRoom != null) ...[
                    _buildInfoCard(
                      title: 'Informasi Kamar',
                      icon: Icons.room,
                      children: [
                        _buildInfoTile(
                          icon: Icons.meeting_room,
                          label: 'Nomor Kamar',
                          value: tenantRoom!.number,
                        ),
                        _buildInfoTile(
                          icon: Icons.category,
                          label: 'Tipe Kamar',
                          value: tenantRoom!.type,
                        ),
                        _buildInfoTile(
                          icon: Icons.payments,
                          label: 'Harga Sewa',
                          value: 'Rp ${_formatPrice(tenantRoom!.price)}/bulan',
                        ),
                        _buildInfoTile(
                          icon: Icons.check_circle_outline,
                          label: 'Fasilitas',
                          value: tenantRoom!.facilities,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Contract Info Card (if checked in)
                  if (isCheckedIn) ...[
                    _buildInfoCard(
                      title: 'Informasi Kontrak',
                      icon: Icons.description,
                      children: [
                        _buildInfoTile(
                          icon: Icons.login,
                          label: 'Tanggal Check-in',
                          value: tenant.checkInDate!.toLocal().toString().split(
                            ' ',
                          )[0],
                        ),
                        _buildInfoTile(
                          icon: Icons.logout,
                          label: 'Tanggal Check-out',
                          value: tenant.checkOutDate!
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                        ),
                        _buildInfoTile(
                          icon: Icons.calendar_today,
                          label: 'Durasi Kontrak',
                          value: '${tenant.durationMonth} bulan',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // KTP Photo (if available)
                  if (tenant.ktpPhoto != null &&
                      tenant.ktpPhoto!.isNotEmpty) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.credit_card,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Foto KTP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(tenant.ktpPhoto!),
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

                  // Checkout Button (if checked in)
                  if (isCheckedIn) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Checkout Tenant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showCheckoutDialog(context, tenant),
                      ),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCheckoutDialog(BuildContext context, Tenant tenant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Checkout Tenant'),
          ],
        ),
        content: Text(
          'Yakin ingin checkout ${tenant.name}?\n\nKamar akan kembali tersedia setelah checkout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await context.read<TenantProvider>().checkOutTenant(
        tenantId: tenant.id!,
        roomId: tenant.roomId!,
      );
      await context.read<RoomProvider>().fetchRooms();

      // Close loading
      if (mounted) Navigator.pop(context);

      // Close detail page
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tenant.name} berhasil checkout'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
