import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'AdminDashboard.dart';
import 'ManagerDashboard.dart';
import 'SalespersonDashboard.dart';
import 'DeliveryPerson.dart';
import 'signup.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login({
    required String username,
    required String password,
    required BuildContext context,
  }) async {
    const String apiUrl = 'https://sona-medico-backend.onrender.com/api/v1/signin';

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        final token = data['token'];
        final role = data['user']['role'];
        final fullName = data['user']['fullName'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setString('username', username);
        await prefs.setString('fullName', fullName);

        Widget nextPage;
        switch (role) {
          case 'admin':
            nextPage = Admindashboard(username: username);
            break;
          case 'manager':
            nextPage = Managerdashboard(username: username);
            break;
          case 'salesperson':
            nextPage = Salespersondashboard(username: username);
            break;
          case 'delivery':
            nextPage = Deliveryperson(username: username);
            break;
          default:
            nextPage = const Scaffold(
              body: Center(child: Text("Unknown role")),
            );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextPage),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${data['message'] ?? response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please login to continue",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a valid username' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) =>
                    value != null && value.length < 6 ? 'Password too short' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        if (_formKey.currentState!.validate()) {
                          _login(
                            username: emailController.text.trim(),
                            password: passwordController.text.trim(),
                            context: context,
                          );
                        }
                      },
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text("Login", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // TextButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => const Signup()),
                  //     );
                  //   },
                  //   child: const Text(
                  //     "Don't have an account? Sign Up",
                  //     style: TextStyle(color: Colors.blue), // You can style it as clickable
                  //   ),
                  // ),

                  TextButton(
                    onPressed: null, // This disables the button
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: Colors.grey), // Optional: show disabled style
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
