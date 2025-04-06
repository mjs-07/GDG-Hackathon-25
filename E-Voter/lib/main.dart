import 'package:flutter/material.dart';
import 'registration_screen.dart';

void main() {
  runApp(EvoterApp());
}

class EvoterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eVoter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EvoterHomeScreen(),
    );
  }
}

class EvoterHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("eVoter App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegistrationScreen()),
              ),
              child: Text("Register as Voter"),
            ),
          ],
        ),
      ),
    );
  }
}
