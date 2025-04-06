import 'package:flutter/material.dart';
import 'verification_screen.dart';

void main() {
  runApp(const CheckMeAsVoterApp());
}

class CheckMeAsVoterApp extends StatelessWidget {
  const CheckMeAsVoterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckMeAsVoter App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const CheckMeAsVoterHomeScreen(),
    );
  }
}

class CheckMeAsVoterHomeScreen extends StatelessWidget {
  const CheckMeAsVoterHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CheckMeAsVoter App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VerificationScreen()),
              ),
              child: const Text("Verify Voter"),
            ),
          ],
        ),
      ),
    );
  }
}
