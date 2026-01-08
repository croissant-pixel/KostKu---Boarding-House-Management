import 'dart:io';
import 'package:flutter/material.dart';
import '../models/tenant_model.dart';
import '../pages/tenant_detail_page.dart';
import '../pages/tenant_form_page.dart';

class TenantTile extends StatelessWidget {
  final Tenant tenant;

  const TenantTile({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    final isActive = tenant.roomId != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TenantDetailPage(tenant: tenant)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar with status
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        tenant.profilePhoto != null &&
                            tenant.profilePhoto!.isNotEmpty
                        ? FileImage(File(tenant.profilePhoto!))
                        : null,
                    child:
                        tenant.profilePhoto == null ||
                            tenant.profilePhoto!.isEmpty
                        ? const Icon(Icons.person, size: 28)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Info
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HP: ${tenant.phone}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Edit button
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TenantFormPage(tenant: tenant),
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
}
