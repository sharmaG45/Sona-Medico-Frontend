import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerCreatePage extends StatefulWidget {
  @override
  _CustomerCreatePageState createState() => _CustomerCreatePageState();
}

class _CustomerCreatePageState extends State<CustomerCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _phone;

  // Submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final customerData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      };

      try {
        final response = await http.post(
          Uri.parse('https://sona-medico-backend.onrender.com/api/v1/create-customer'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(customerData),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer created successfully')),
          );

          // Clear the form
          _formKey.currentState?.reset();
          _nameController.clear();
          _emailController.clear();
          _addressController.clear();

          // Keep the phone number pre-filled and non-editable
          _phoneController.text = _phone ?? '';

          Navigator.pushReplacementNamed(context, '/stockData', arguments: customerData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create customer')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phoneData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (phoneData != null && phoneData.containsKey('phone')) {
        _phone = phoneData['phone'];
        _phoneController.text = _phone!;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Customer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter customer name',
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter customer email',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an email';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _phoneController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                ),
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter customer address',
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter an address' : null,
              ),
              const SizedBox(height: 32.0),

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
