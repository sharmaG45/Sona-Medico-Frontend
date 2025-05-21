import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:country_state_city_pro/country_state_city_pro.dart';

class CustomerCreatePage extends StatefulWidget {
  @override
  _CustomerCreatePageState createState() => _CustomerCreatePageState();
}

class _CustomerCreatePageState extends State<CustomerCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // Country picker controllers
  final TextEditingController country = TextEditingController();
  final TextEditingController state = TextEditingController();
  final TextEditingController city = TextEditingController();

  String? _phone;

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final customerData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address_line_1': _addressLine1Controller.text,
        'address_line_2': _addressLine2Controller.text,
        'pincode': _pincodeController.text,
        'country': country.text,
        'state': state.text,
        'city': city.text,
      };

      try {
        final response = await http.post(
          Uri.parse('https://sona-medico-backend.onrender.com/api/v1/create-customer'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(customerData),
        );
        
        
        print("Response Status,${response.statusCode}");

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Customer created successfully!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );


          _formKey.currentState?.reset();
          _nameController.clear();
          _emailController.clear();
          _addressLine1Controller.clear();
          _addressLine2Controller.clear();
          _pincodeController.clear();
          country.clear();
          state.clear();
          city.clear();
          _phoneController.text = _phone ?? '';

          Navigator.pushReplacementNamed(context, '/stockData', arguments: customerData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to create customer. Please try again.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );

        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An unexpected error occurred. ${e.toString()}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
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
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _pincodeController.dispose();
    country.dispose();
    state.dispose();
    city.dispose();
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
                enabled: true,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                ),
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _addressLine1Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 1',
                  hintText: 'House number, street, etc.',
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter address line 1' : null,
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _addressLine2Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 2',
                  hintText: 'Area, locality (optional)',
                ),
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pincode',
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter a pincode' : null,
              ),
              const SizedBox(height: 16.0),

              CountryStateCityPicker(
                country: country,
                state: state,
                city: city,
                dialogColor: Colors.grey.shade200,
                textFieldDecoration: InputDecoration(
                  fillColor: Colors.blueGrey.shade100,
                  filled: true,
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),

              // const SizedBox(height: 20),
              // Text(
              //   "Selected: ${country.text}, ${state.text}, ${city.text}",
              //   style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              // ),

              const SizedBox(height: 20),
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
