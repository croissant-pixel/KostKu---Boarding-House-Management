import 'package:flutter/material.dart';
import 'package:kostku/features/property/pages/kost_profile_page.dart';
import 'package:kostku/features/property/pages/room_form_page.dart';
import 'package:kostku/features/tenant/providers/tenant_provider.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../widgets/room_card.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}


class _RoomListPageState extends State<RoomListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<RoomProvider>().fetchRooms();
      context.read<TenantProvider>().fetchTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kamar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_work),
            tooltip: 'Profil Kost',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => KostProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Consumer<RoomProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.rooms.isEmpty) { 
            return const Center(child: Text('Belum ada kamar'));
          }

          return ListView.builder(
            itemCount: provider.rooms.length,
            itemBuilder: (context, index) {
              final room = provider.rooms[index];
              return RoomCard(room: room);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoomFormPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
