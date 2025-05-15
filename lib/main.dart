import 'package:flutter/material.dart';
import 'splashscreen.dart';
import 'StockListScreen.dart';
import 'create_customer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sona Medical',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        '/stockData': (context) => StockListScreen(),
        '/createCustomer': (context) => CustomerCreatePage(),
      },
      home:SplashScreen(),
    );
  }
}


