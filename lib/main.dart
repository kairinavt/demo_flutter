import 'package:flutter/material.dart';
import 'package:money_management/database/database_helper.dart';
import 'package:money_management/pages/category_page.dart';
import 'package:money_management/pages/home_page.dart';
import 'package:money_management/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      theme: ThemeData(primarySwatch: Colors.amber),
      routes: {
        HomePage.routeName: (ctx) => HomePage(key: UniqueKey()),
        CategoryPage.routeName: (ctx) => CategoryPage()
      },
    );
  }
}
