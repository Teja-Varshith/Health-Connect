import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/app/routes.dart';
import 'package:health_connect/app/theme.dart';
import 'package:health_connect/firebase_options.dart';
import 'package:routemaster/routemaster.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );        

  runApp( ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget{
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ref.read(ThemeProvider),
      title: 'HealthConnect - AI Health Companion',
      routerDelegate: RoutemasterDelegate(
        routesBuilder: (context) {
          final routes = isLoggedIn ? loggedInRoutes : loggedOutRoutes;
          return routes;
        },  
      ),
      
      routeInformationParser: const RoutemasterParser(),
    );
  }
}