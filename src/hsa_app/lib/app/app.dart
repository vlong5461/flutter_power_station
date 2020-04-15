import 'package:flutter/material.dart';
import 'package:hsa_app/app/boot.dart';
import 'package:hsa_app/page/welcome/welcome_page.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    BootApp.boot();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '智能电站',
      debugShowCheckedModeBanner: false,
      home: WelcomePage(),
    );
  }
}
