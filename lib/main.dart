import 'package:flutter/material.dart';
import 'package:kostku/features/auth/providers/user_provider.dart';
import 'package:kostku/features/property/providers/inspection_provider.dart';
import 'package:kostku/features/property/providers/kost_provider.dart';
import 'package:kostku/features/property/providers/room_provider.dart';
import 'package:kostku/features/tenant/providers/tenant_provider.dart';
import 'package:provider/provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = RoomProvider();
            provider.fetchRooms(); // fetch saat provider dibuat
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = KostProvider();
            provider.fetchKost(); // kalau perlu fetch kost
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => InspectionProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = TenantProvider();
            provider.fetchTenants(); // fetch tenant langsung
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

