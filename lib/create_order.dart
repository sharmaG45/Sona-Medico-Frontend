import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String productName = '';
  String customerName = '';
  String customerPhone = '';
  int quantity = 1;
  double price = 0.0;
  String? selectedSalesperson;
  String? selectedSalespersonName;

  List<dynamic> salespeople = [];
  bool isFetchingSalespeople = false;

  final TextEditingController _salespersonController = TextEditingController();

  @override
  void dispose() {
    _salespersonController.dispose();
    super.dispose();
  }

  Future<void> _loadSalespeople() async {
    if (salespeople.isNotEmpty) return;

    setState(() => isFetchingSalespeople = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized: Token not found')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.29.253:3000/api/v1/salespeople'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          salespeople = jsonDecode(response.body);
        });
      } else {
        throw Exception('Failed to fetch salespeople');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching salespeople: $e')),
      );
    } finally {
      setState(() => isFetchingSalespeople = false);
    }
  }

  void _showSalespersonSelector() async {
    await _loadSalespeople();
    if (salespeople.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: salespeople.map((salesperson) {
          final name = salesperson['fullName'] ?? 'Unnamed';
          final id = salesperson['id']?.toString();

          return ListTile(
            title: Text(name),
            onTap: () {
              setState(() {
                selectedSalesperson = id;
                selectedSalespersonName = name;
                _salespersonController.text = name;
              });
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _submitOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unauthorized: Token not found')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.29.253:3000/api/v1/createOrder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productName': productName,
          'customerName': customerName,
          'customerPhone':customerPhone,
          'quantity': quantity,
          'price': price,
          'salespersonId': selectedSalesperson,
          'salespersonName':selectedSalespersonName,
        }),
      );
      print("Response Data,$response");
      if (response.statusCode == 200) {
        // Send notification via backend API
        await http.post(
          Uri.parse('http://192.168.29.253:3000/api/v1/sendNotification'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'salespersonId': selectedSalesperson,
            'title': 'New Order Assigned',
            'body': 'An order for $productName has been assigned to you.',
          }),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order created successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Product Name'),
                onChanged: (val) => productName = val,
                validator: (val) =>
                val!.isEmpty ? 'Enter a product name' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Customer Name'),
                onChanged: (val) => customerName = val,
                validator: (val) =>
                val!.isEmpty ? 'Enter a customer name' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Customer Phone',
                ),
                keyboardType: TextInputType.phone,
                onChanged: (val) => customerPhone = val,
                validator: (val) =>
                val == null || val.length < 10 ? 'Enter a valid phone number' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                onChanged: (val) => quantity = int.tryParse(val) ?? 1,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                onChanged: (val) => price = double.tryParse(val) ?? 0.0,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showSalespersonSelector,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _salespersonController,
                    decoration: InputDecoration(
                      labelText: 'Assign Salesperson',
                      suffixIcon: isFetchingSalespeople
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : const Icon(Icons.arrow_drop_down),
                    ),
                    validator: (val) => selectedSalesperson == null
                        ? 'Please select a salesperson'
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submitOrder();
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
