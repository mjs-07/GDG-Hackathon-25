import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  XFile? _imageFile;
  String? _nfcId;
  String? _userPhoneNumber;

  final TwilioFlutter twilioFlutter = TwilioFlutter(
    accountSid: 'your_account_sid',
    authToken: 'your_auth_token',
    twilioNumber: 'your_twilio_number',
  );

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  Future<void> _authenticateUser() async {
    if (_imageFile == null || _nfcId == null) return;

    var uri = Uri.parse('https://face-recognition-api-8qcu.onrender.com');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      _handleNFCLogic();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Authentication Failed")));
    }
  }

  void _handleNFCLogic() async {
    DocumentReference docRef = FirebaseFirestore.instance.collection('nfc_logs').doc(_nfcId);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        transaction.set(docRef, {'IN': true, 'OUT': false});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checked IN")));
      } else {
        bool isIn = snapshot['IN'];
        bool isOut = snapshot['OUT'];
        if (isIn && !isOut) {
          transaction.update(docRef, {'OUT': true});
          _sendSMS();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checked OUT")));
        } else if (isIn && isOut) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Access Denied. Already Checked OUT.")));
        }
      }
    });
  }

  void _sendSMS() {
    if (_userPhoneNumber != null) {
      twilioFlutter.sendSMS(
        toNumber: _userPhoneNumber!,
        messageBody: 'You have successfully checked OUT.',
      );
    }
  }

  void _readNFC() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      setState(() {
        _nfcId = tag.data['id'].toString();
      });

      // Fetch user phone number
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(_nfcId).get();
      if (snapshot.exists) {
        _userPhoneNumber = snapshot['phone'];
      }

      _pickImage();
    });
  }

  @override
  void initState() {
    super.initState();
    _readNFC();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verification")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _imageFile != null ? Image.file(File(_imageFile!.path)) : Container(),
            ElevatedButton(onPressed: _pickImage, child: const Text("Capture Face")),
            ElevatedButton(onPressed: _authenticateUser, child: const Text("Authenticate")),
          ],
        ),
      ),
    );
  }
}
