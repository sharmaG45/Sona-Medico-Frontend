import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerCreatePage extends StatefulWidget {
  @override
  _CustomerCreatePageState createState() => _CustomerCreatePageState();
}

class _CustomerCreatePageState extends State<CustomerCreatePage> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _email;
  String? _phone;
  String? _address;

  // Function to handle form submission and API call
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // If the form is valid, save the values
      _formKey.currentState?.save();

      // Prepare the data to send to the API
      final Map<String, dynamic> customerData = {
        'name': _name,
        'email': _email,
        'phone': _phone,
        'address': _address,
      };

      // Send a POST request to the API
      try {
        final response = await http.post(
          Uri.parse('https://sona-medico-backend.onrender.com/api/v1/create-customer'), // Replace with your API URL
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(customerData), // Encode the data to JSON
        );

        if (response.statusCode == 200) {
          // If the API call is successful
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer created successfully')),
          );
          // Optionally, navigate to another page after submission
          // Navigator.pushNamed(context, '/successPage');
        } else {
          // If the API call fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create customer')),
          );
        }
      } catch (e) {
        // If there is an error making the API call
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // Name input field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter customer name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value;
                },
              ),
              const SizedBox(height: 16.0),

              // Email input field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter customer email',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value;
                },
              ),
              const SizedBox(height: 16.0),

              // Phone input field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter customer phone number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
                onSaved: (value) {
                  _phone = value;
                },
              ),
              const SizedBox(height: 16.0),

              // Address input field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter customer address',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
                onSaved: (value) {
                  _address = value;
                },
              ),
              const SizedBox(height: 32.0),

              // Submit button
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Create Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
