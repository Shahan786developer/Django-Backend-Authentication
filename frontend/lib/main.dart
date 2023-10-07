import 'package:flutter/material.dart';
import 'package:frontend/pinverification.dart';
import 'registration_form.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
// Add this import for timer
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure that Flutter is initialized

  // Load the username from SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedUsername = prefs.getString('username');

  runApp(MyApp(initialUsername: savedUsername));
}

class MyApp extends StatelessWidget {
  final String? initialUsername;

  MyApp({this.initialUsername});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: initialUsername != null
          ? PinVerificationScreen(
              username:
                  initialUsername!) // Show home page if username is present
          : MainPage(), // Show login page if no username is present
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String message = '';
  String uname = '';

  // Add a timer to automatically log out after 5 minutes of inactivity
  Timer? _logoutTimer;

  @override
  void initState() {
    super.initState();
    // Start the logout timer when the login page is first displayed
    _startLogoutTimer();
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    _logoutTimer?.cancel(); // Cancel the timer when the page is disposed
    super.dispose();
  }

  Future<void> login(
      String username, String phoneNumber, String password) async {
    final apiUrl = 'http://127.0.0.1:8000/Login/';

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: jsonEncode({
        'username': username,
        'phonenumber': phoneNumber,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String token = responseData['jwt'];
      setState(() {
        message = responseData['message'];
        uname = responseData['uname'];
      });

      // Store the username in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('username', uname);

      // Redirect to PIN verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinVerificationScreen(
            username: uname,
          ),
        ),
      );
    } else {
      final Map<String, dynamic> responseData = json.decode(response.body);
      setState(() {
        message = responseData['message'];
      });
    }
  }

  // Start the logout timer
  void _startLogoutTimer() {
    _logoutTimer = Timer(Duration(minutes: 1), () {
      // Logout the user after 5 minutes of inactivity but i hre just oneminute to see effect
      logout();
    });
  }

  // Logout the user
  void logout() {
    // Delete the stored username from SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('username');
    });

    // Redirect to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Number and Password Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                controller: phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Enter Phone Number',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Enter Username',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Enter Password',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final username = usernameController.text;
                final phonenumber = phoneNumberController.text;
                final password = passwordController.text;
                await login(username, phonenumber, password);

                // Reset the logout timer after successful login
                _logoutTimer?.cancel();
                _startLogoutTimer();
              },
              child: Text('Login'),
            ),
            SizedBox(height: 16),
            Text(
              '$message $uname',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to the login page
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: Text('Login'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to the registration page
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RegistrationForm()));
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
