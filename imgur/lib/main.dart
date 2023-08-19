import 'package:flutter/material.dart';
import 'homepage.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  static const String _title = 'Gallery App';
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: _title,
    debugShowCheckedModeBanner: false,
    home: MyHomePage(title: 'Gallery'),
  );
}