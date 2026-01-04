import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kostku/features/tenant/pages/tenant_form_page.dart';
import '../models/tenant_model.dart';
import '../pages/tenant_detail_page.dart';

class TenantTile extends StatelessWidget {
  final Tenant tenant;

  const TenantTile({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        onTap: () {
          // buka tenant detail page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TenantDetailPage(tenant: tenant)),
          );
        },
        leading: tenant.profilePhoto != null && tenant.profilePhoto!.isNotEmpty
            ? CircleAvatar(
                backgroundImage: FileImage(File(tenant.profilePhoto!)),
              )
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(tenant.name),
        subtitle: Text('HP: ${tenant.phone}'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // Buka halaman edit tenant
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TenantFormPage(tenant: tenant)),
            );
          },
        ),
      ),
    );
  }
}
