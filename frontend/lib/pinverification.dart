import 'dart:convert';
import 'package:frontend/main.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatelessWidget {
  final String username;
  // You need to pass phoneNumber to this widget

  SettingsPage({required this.username});

  // Function to handle logout
  void _logout(BuildContext context) async {
    // Clear the username from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('username');

    // Navigate back to the login page and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name of User: $username'),
              Text('Number of User: ######'),
              SizedBox(
                  height: 20), // Add spacing between the texts and the button
              ElevatedButton(
                onPressed: () {
                  // Call the logout function when the user presses the logout button
                  _logout(context);
                },
                child: Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final String username;

  HomePage({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          // Add a settings icon to the app bar
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to the SettingsPage when the settings icon is clicked
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SettingsPage(username: username)),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to the Home Page, $username!'),
          ],
        ),
      ),
    );
  }
}

class WaitingPage extends StatelessWidget {
  final String username;

  WaitingPage({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waiting Page'),
        actions: [
          // Add a settings icon to the app bar
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to the SettingsPage when the settings icon is clicked
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SettingsPage(username: username)),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to the Waiting Page, $username!'),
          ],
        ),
      ),
    );
  }
}

class PinVerificationScreen extends StatelessWidget {
  final String username;

  PinVerificationScreen({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PIN Verification"),
      ),
      body: PinVerificationForm(username: username),
    );
  }
}

class PinVerificationForm extends StatefulWidget {
  final String username;

  PinVerificationForm({required this.username});

  @override
  _PinVerificationFormState createState() => _PinVerificationFormState();
}

class _PinVerificationFormState extends State<PinVerificationForm> {
  String enteredPin = "";

  void _addDigit(String digit) {
    setState(() {
      enteredPin += digit;
    });
  }

  void _removeDigit() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
      });
    }
  }

  void _verifyPin(BuildContext context) async {
    final apiUrl = 'http://127.0.0.1:8000/pin/';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pin': enteredPin, 'username': widget.username}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final bool isPinCorrect = responseData['isPinCorrect'];
      final bool isVerified = responseData['isVerified'];

      if (isPinCorrect) {
        if (isVerified) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(username: widget.username),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WaitingPage(username: widget.username),
            ),
          );
        }
      }
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final errorMessage = responseData['message'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "Enter your 4-digit PIN",
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          Text(
            enteredPin, // Display the entered PIN
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildNumberButton("1"),
              _buildNumberButton("2"),
              _buildNumberButton("3"),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildNumberButton("4"),
              _buildNumberButton("5"),
              _buildNumberButton("6"),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildNumberButton("7"),
              _buildNumberButton("8"),
              _buildNumberButton("9"),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildNumberButton("0"),
              _buildActionButton("Backspace"),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              _verifyPin(context);
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String digit) {
    return ElevatedButton(
      onPressed: () => _addDigit(digit),
      child: Text(digit),
    );
  }

  Widget _buildActionButton(String label) {
    return TextButton(
      onPressed: () {
        if (label == "Backspace") {
          _removeDigit();
        }
      },
      child: Text(label),
    );
  }
}
