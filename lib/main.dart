import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/app/routes.dart';
import 'package:health_connect/app/theme.dart';
import 'package:health_connect/firebase_options.dart';
import 'package:health_connect/providers/user_provider.dart';
import 'package:routemaster/routemaster.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
