import 'package:flutter/material.dart';
import 'package:meru_tech_assignment/screens/quote_list.dart';
import 'package:meru_tech_assignment/screens/quote_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Quote Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const QuoteListScreen(),
      routes: {
        '/preview': (context) => const QuotePreviewScreen(),
      },
    );
  }
}


