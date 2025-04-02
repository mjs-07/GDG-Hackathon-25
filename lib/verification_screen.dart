import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter_sms/flutter_sms.dart';

class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String readNfcSerial = '';
  Map<String, dynamic>? userData;
  bool isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> nfcDetectionCount = {}; // Track detection count for each NFC
  Map<String, String> nfcInOutStatus = {}; // Track 'in' or 'out' status

  Future<void> _readNFCVerification() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      // Handle NFC not available (e.g., show a SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NFC is not available on this device.')),
      );
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        String serial = tag.data.toString();
        setState(() {
          readNfcSerial = serial;
          isLoading = true; // Start loading
          userData = null; // Clear previous data
        });
        await _processNfcTag(serial);
        NfcManager.instance.stopSession();
      },
    );
  }

  Future<void> _processNfcTag(String nfcSerial) async {
    // Increment the detection count for this NFC
    nfcDetectionCount[nfcSerial] = (nfcDetectionCount[nfcSerial] ?? 0) + 1;
    int count = nfcDetectionCount[nfcSerial]!;

    await _fetchUserData(nfcSerial, count);
  }

  Future<void> _fetchUserData(String nfcSerial, int detectionCount) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('users')
          .where('nfcSerial', isEqualTo: nfcSerial)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          userData = querySnapshot.docs.first.data();
        });

        // Determine 'in' or 'out' status
        String status;
        if (detectionCount % 2 != 0) {
          status = 'in';
        } else {
          status = 'out';
          // Send SMS when status is 'out'
          _sendVoteCastedSMS(userData?['phone'], userData?['name']);
        }
        nfcInOutStatus[nfcSerial] = status;

      } else {
        setState(() {
          userData = null;
          nfcInOutStatus[nfcSerial] = 'unknown';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('NFC not found in the database.')),
        );
      }
    } catch (e) {
      setState(() {
        userData = null;
        nfcInOutStatus[nfcSerial] = 'error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendVoteCastedSMS(String? phoneNumber, String? personName) async {
    if (phoneNumber != null && personName != null) {
      try {
        List<String> recipients = [phoneNumber];
        String message = '$personName vote has been casted';
        String? result = await FlutterSms.sendSMS(
          message: message,
          recipients: recipients,
          sendDirect: true, // Set to true to attempt direct send
        );
        print('SMS sent: $result'); // Log the result of sending
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending SMS: $e')),
        );
        print('Error sending SMS: $e');
      }
    } else {
      print('Phone number or person name is null, cannot send SMS.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verification')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: isLoading ? null : _readNFCVerification,
                child: Text('Read NFC'),
              ),
              SizedBox(height: 20),
              if (isLoading)
                CircularProgressIndicator()
              else if (userData != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${userData?['name'] ?? 'N/A'}'),
                    Text('Phone: ${userData?['phone'] ?? 'N/A'}'),
                    Text('Address: ${userData?['address'] ?? 'N/A'}'),
                    Text('Age: ${userData?['age'] ?? 'N/A'}'),
                    Text('Gender: ${userData?['gender'] ?? 'N/A'}'),
                    Text('Status: ${nfcInOutStatus[readNfcSerial] ?? 'N/A'}'),
                    // Display other details as needed
                  ],
                )
              else if (readNfcSerial.isNotEmpty)
                Text('User data not found for NFC: $readNfcSerial')
              else
                Text('Tap NFC tag to verify.'),
            ],
          ),
        ),
      ),
    );
  }
}