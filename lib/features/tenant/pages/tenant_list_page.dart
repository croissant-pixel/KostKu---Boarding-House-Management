import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tenant_provider.dart';
import '../models/tenant_model.dart';
import 'tenant_form_page.dart';
import 'tenant_detail_page.dart';

class TenantListPage extends StatefulWidget {
  const TenantListPage({super.key});

  @override
  State<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends State<TenantListPage> {
  String _searchQuery = '';
  bool _showActive = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TenantProvider>().fetchTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar with Gradient
            _buildAppBar(),
            
            // Search Bar
            _buildSearchBar(),
            
            // Filter Chips
            _buildFilterChips(),
            
            // Tenant List
            Expanded(
              child: Consumer<TenantProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var tenants = provider.tenants;
                  
                  // Filter by active/inactive
                  tenants = tenants.where((t) {
                    if (_showActive) {
                      return t.roomId != null;
                    } else {
                      return t.roomId == null;
                    }
                  }).toList();

                  // Filter by search
                  if (_searchQuery.isNotEmpty) {
                    tenants = tenants.where((t) {
                      return t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          t.phone.contains(_searchQuery) ||
                          t.email.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();
                  }

                  if (tenants.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchTenants(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tenants.length,
                      itemBuilder: (context, index) {
                        return _buildTenantCard(tenants[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TenantFormPage()),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Tenant'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Daftar Penyewa',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: () {
                  // TODO: Show filter options
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Consumer<TenantProvider>(
            builder: (context, provider, _) {
              final activeCount = provider.tenants.where((t) => t.roomId != null).length;
              final totalCount = provider.tenants.length;
              
              return Text(
                '$activeCount aktif dari $totalCount total penyewa',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari nama, nomor HP, atau email...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Aktif'),
            selected: _showActive,
            onSelected: (value) {
              setState(() {
                _showActive = true;
              });
            },
            selectedColor: Colors.green.shade100,
            checkmarkColor: Colors.green,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Tidak Aktif'),
            selected: !_showActive,
            onSelected: (value) {
              setState(() {
                _showActive = false;
              });
            },
            selectedColor: Colors.orange.shade100,
            checkmarkColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildTenantCard(Tenant tenant) {
    final isActive = tenant.roomId != null;
    final hasCheckout = tenant.checkOutDate != null;
    final daysRemaining = hasCheckout 
        ? tenant.checkOutDate!.difference(DateTime.now()).inDays 
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TenantDetailPage(tenant: tenant),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with Status Badge
              Stack(
                children: [
                  Hero(
                    tag: 'tenant_${tenant.id}',
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: tenant.profilePhoto != null &&
                              tenant.profilePhoto!.isNotEmpty
                          ? FileImage(File(tenant.profilePhoto!))
                          : null,
                      child: tenant.profilePhoto == null ||
                              tenant.profilePhoto!.isEmpty
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Tenant Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          tenant.phone,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isActive && daysRemaining != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: daysRemaining <= 7
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          daysRemaining <= 0
                              ? 'Kontrak habis'
                              : '$daysRemaining hari tersisa',
                          style: TextStyle(
                            fontSize: 11,
                            color: daysRemaining <= 7
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else if (!isActive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Tidak Aktif',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action Button
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TenantDetailPage(tenant: tenant),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showActive ? Icons.people_outline : Icons.person_off_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _showActive ? 'Belum ada penyewa aktif' : 'Tidak ada penyewa tidak aktif',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showActive 
                ? 'Tambahkan penyewa baru untuk memulai'
                : 'Semua penyewa sedang aktif',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_showActive) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TenantFormPage()),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah Penyewa'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}