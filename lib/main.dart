import 'package:admin_app/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://vikweyufqcgpnoyqxmld.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZpa3dleXVmcWNncG5veXF4bWxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ5MjkxNDgsImV4cCI6MjA1MDUwNTE0OH0.X1Fb8H9j8ryh14M4AlyjJkrWK-WJWG4Yq0aj-tfklIg',
  );
  runApp(const MainApp());
}

final supabase = Supabase.instance.client;
        

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home:DashboardPage()
    );
  }
}
