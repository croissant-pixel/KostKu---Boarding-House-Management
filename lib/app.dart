import 'package:flutter/material.dart';
import 'package:kostku/features/property/pages/room_list_page.dart';
import 'package:kostku/features/tenant/pages/tenant_list_page.dart';
import 'features/home/pages/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KostKu',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const RoomListPage(),
    );
  }
}
