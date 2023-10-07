import 'package:flutter/material.dart';
import 'package:frontend/pinverification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserRegistration {
  String username = '';
  String phoneNumber = '';
  String password = '';
  String confirmPassword = ''; // Added confirmPassword field
  String pin = '';
}

class RegistrationForm extends StatefulWidget {
  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final UserRegistration userRegistration = UserRegistration();
  int _currentStep = 0;

  final List<String> stepTitles = [
    'Username',
    'Phone Number',
    'Password',
    'Confirm Password', // Updated step title
    'PIN',
  ];

  final List<TextEditingController> controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  String errorMessage = '';

  // Validate password format
  bool isPasswordValid(String password) {
    final passwordRegex =
        r'^(?=.*[A-Z])(?=.*[\W_])(.{12,})$'; // At least 12 characters, one uppercase letter, and one special character
    return RegExp(passwordRegex).hasMatch(password);
  }

  // Validate PIN format
  // bool isPinValid(String pin) {
  //   return pin.length >= 4 && pin.length <= 6;
  // }
  bool isPinValid(String pin) {
    if (pin.length >= 4 &&
        pin.length <= 6 &&
        pin.contains(RegExp(r'^[0-9]+$'))) {
      return true;
    }
    return false;
  }

  bool isNumeric(String text) {
    return double.tryParse(text) != null;
  }

  Future<void> registerUser() async {
    for (int i = 0; i < controllers.length; i++) {
      if (controllers[i].text.isEmpty) {
        setState(() {
          errorMessage = 'All fields are required.';
        });
        return;
      }
    }

    // if (userRegistration.password != userRegistration.confirmPassword) {
    //   setState(() {
    //     errorMessage = 'Passwords do not match.';
    //   });
    //   return;
    // }

    userRegistration.username = controllers[0].text;
    userRegistration.phoneNumber = controllers[1].text;
    userRegistration.password = controllers[2].text;
    userRegistration.confirmPassword =
        controllers[3].text; // Updated confirmPassword
    userRegistration.pin = controllers[4].text;

    // Here, you should add your registration logic, such as making an API request
    // Replace the following comments with your registration API call

    final String url = 'http://127.0.0.1:8000/';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': userRegistration.username,
        'phone_number': userRegistration.phoneNumber,
        'password': userRegistration.password,
        'pins': userRegistration.pin,
      }),
    );

    if (response.statusCode == 201) {
      setState(() {
        errorMessage = 'User registered successfully!';
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('username', userRegistration.username);

      // Navigate to the waiting page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WaitingPage(username: userRegistration.username),
        ),
      );
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      setState(() {
        errorMessage = responseData['message'];
      });
    } else {
      setState(() {
        errorMessage = 'An error occurred.';
      });
    }

    // If registration is successful, you can clear the form or navigate to another page
    // Clear the form
    for (int i = 0; i < controllers.length; i++) {
      controllers[i].clear();
    }
  }

  // Validate if data is filled in the current step
  bool isStepDataFilled(int step) {
    return controllers[step].text.isNotEmpty;
  }

  void nextStep() {
    if (_currentStep < controllers.length - 1) {
      if (isStepDataFilled(_currentStep)) {
        if (_currentStep == 0) {
          verifyUsername();
        }
        if (_currentStep == 1) {
          final String phonenumber = controllers[1].text;
          if (phonenumber.length < 7 ||
              phonenumber.length > 12 ||
              !isNumeric(phonenumber)) {
            setState(() {
              errorMessage =
                  'Phone number must be Numeric and between 7 and 12 characters long.';
            });
            return;
          }

          verifyPhoneNumber();
        }
        final t = controllers[2].text;
        if (_currentStep == 2) {
          if (!isPasswordValid(t)) {
            print(t);
            setState(() {
              errorMessage =
                  'Password must be at least 12 characters long, contain atleast one uppercase letter, and one special character.';
            });
            return;
          }
        }
        if (_currentStep == 3) {
          if (controllers[2].text != controllers[3].text) {
            setState(() {
              errorMessage = 'Passwords do not match.';
            });
            return;
          }
        }
        if (_currentStep == 4) {
          final String pinText = controllers[4].text;
          print(pinText);
          if (isPinValid(pinText)) {
            setState(() {
              errorMessage =
                  'PIN must be Numeric and between 4 and 6 characters long.';
              _currentStep--; // Go back to the PIN step
            });
            return;
          }
        }
        setState(() {
          _currentStep++;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'This field is required.';
        });
      }
    } else if (_currentStep == controllers.length - 1) {
      final String pinText = controllers[4].text;
      if (!isPinValid(pinText)) {
        setState(() {
          errorMessage =
              'PIN must be Numeric and between 4 and 6 characters long.';
        });
        return;
      }
      registerUser();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> verifyPhoneNumber() async {
    final String phonenumber = controllers[1].text;

    final String url =
        'http://127.0.0.1:8000/PhoneNumber/'; // Replace with your API endpoint for phone number verification
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phonenumber': phonenumber,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        errorMessage = '';
      });
    } else if (response.statusCode == 400) {
      setState(() {
        errorMessage = 'PhoneNumber already Existed!';
        _currentStep--;
      });
    }
  }

  Future<void> verifyUsername() async {
    final String username = controllers[0].text;
    if (username.isEmpty) {
      return;
    } else {
      final String url =
          'http://127.0.0.1:8000/VerifyUsername/'; // Replace with your API endpoint for username verification
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          errorMessage = '';
        });
      } else if (response.statusCode == 400) {
        setState(() {
          errorMessage = 'User already Existed!';
          _currentStep--;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration Form'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20.0),
              children: <Widget>[
                Text(
                  stepTitles[_currentStep],
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextFormField(
                  controller: controllers[_currentStep],
                  decoration: InputDecoration(
                      labelText: 'Enter your ${stepTitles[_currentStep]}'),
                  obscureText: stepTitles[_currentStep] == 'Password' ||
                      stepTitles[_currentStep] ==
                          'Confirm Password', // Hide password fields
                ),
                SizedBox(height: 20.0),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: nextStep,
            child: Text(
                _currentStep == controllers.length - 1 ? 'Register' : 'Next'),
          ),
          if (_currentStep > 0)
            ElevatedButton(
              onPressed: previousStep,
              child: Text('Previous'),
            ),
          SizedBox(height: 20.0),
          Text(
            errorMessage,
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
