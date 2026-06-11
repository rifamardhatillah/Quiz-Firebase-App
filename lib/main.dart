import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/add_edit_screen.dart';
import '../screens/about_screen.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/student_model.dart';
import '../screens/register_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDj09Tevl-TTCrgQi2ga__Kugex4Hp_x28",
      authDomain: "quiz-77801.firebaseapp.com",
      projectId: "quiz-77801",
      storageBucket: "quiz-77801.firebasestorage.app",
      messagingSenderId: "461488887549",
      appId: "1:461488887549:web:99aaedada2f83494595094",
      measurementId: "G-Z6SQGYV4D4",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<StorageService>(create: (_) => StorageService()),
      ],
      child: MaterialApp(
        title: 'Student Data App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
        ),
        initialRoute: '/splash',
        routes: {
         '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/detail': (context) {
            final student =
                ModalRoute.of(context)!.settings.arguments as Student;
            return DetailScreen(student: student);
          },
          '/add': (context) => const AddEditScreen(),
          '/edit': (context) {
            final student =
                ModalRoute.of(context)!.settings.arguments as Student;
            return AddEditScreen(student: student);
          },
          '/about': (context) => const AboutScreen(),
        },
      ),
    );
  }
}
