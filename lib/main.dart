import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/app/routes.dart';
import 'package:health_connect/app/theme.dart';
import 'package:health_connect/firebase_options.dart';
import 'package:health_connect/providers/user_provider.dart';
import 'package:routemaster/routemaster.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TODO: Replace with your Supabase project URL and anon key
  await Supabase.initialize(
    url: 'https://gcgmapbczlophcztzcvj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjZ21hcGJjemxvcGhjenR6Y3ZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE2OTI0MDEsImV4cCI6MjA0NzI2ODQwMX0.FzDN31kSqG6GR_k8jjWKX01WIcTJyDjQfcLIU3KRsFk',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(appInitProvider);
    final userState = ref.watch(userProvider);

    return init.when(
      loading: () => MaterialApp(
        theme: ref.read(ThemeProvider),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => _buildApp(ref, loggedOutRoutes),
      data: (_) {
        if (userState == null) {
          return _buildApp(ref, loggedOutRoutes);
        }

        if (!userState.isProfileComplete) {
          return _buildApp(ref, profileSetupRoutes);
        }

        final routes = userState.isCaretaker ? caretakerRoutes : memberRoutes;
        return _buildApp(ref, routes);
      },
    );
  }

  MaterialApp _buildApp(WidgetRef ref, RouteMap routes) {
    return MaterialApp.router(
      key: ValueKey(routes),
      theme: ref.read(ThemeProvider),
      title: 'HealthConnect',
      debugShowCheckedModeBanner: false,
      routerDelegate: RoutemasterDelegate(routesBuilder: (_) => routes),
      routeInformationParser: const RoutemasterParser(),
    );
  }
}
