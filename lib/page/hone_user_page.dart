import 'package:flutter/material.dart';

class Userhome extends StatefulWidget {
  const Userhome({super.key});

  @override
  State<Userhome> createState() => _UserhomeState();
}

class _UserhomeState extends State<Userhome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User')),
      body: Container(child: Column(children: [Text('hello user')])),
    );
  }
}