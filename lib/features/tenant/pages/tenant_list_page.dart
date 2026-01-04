import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tenant_provider.dart';
import '../models/tenant_model.dart';
import 'tenant_form_page.dart';
import '../widgets/tenant_tile.dart'; // import widget baru

class TenantListPage extends StatelessWidget {
  const TenantListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tenant List')),
      body: Consumer<TenantProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading)
            return const Center(child: CircularProgressIndicator());
          if (provider.tenants.isEmpty)
            return const Center(child: Text('Belum ada tenant'));
          return ListView.builder(
            itemCount: provider.tenants.length,
            itemBuilder: (context, index) {
              final tenant = provider.tenants[index];
              return TenantTile(tenant: tenant); // pakai widget baru
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TenantFormPage()),
        ),
      ),
    );
  }
}
