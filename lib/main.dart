import 'package:flutter/material.dart';
import 'package:kostku/core/services/notification_service.dart';
import 'package:kostku/features/auth/providers/user_provider.dart';
import 'package:kostku/features/payment/providers/payment_provider.dart';
import 'package:kostku/features/property/providers/inspection_provider.dart';
import 'package:kostku/features/property/providers/kost_provider.dart';
import 'package:kostku/features/property/providers/room_provider.dart';
import 'package:kostku/features/tenant/providers/tenant_provider.dart';
import 'package:provider/provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = RoomProvider();
            provider.fetchRooms();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = KostProvider();
            provider.fetchKost();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => InspectionProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = TenantProvider();
            provider.fetchTenants();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = PaymentProvider();
            provider.fetchPayments();
            provider.fetchAnalytics();
            return provider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

