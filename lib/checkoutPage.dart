import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final double totalPrice;
  final int totalQuantity;

  const CheckoutPage({
    Key? key,
    required this.cart,
    required this.totalPrice,
    required this.totalQuantity,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? selectedSalesperson;
  List<String> salespersons = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchSalespersons();
  }

  Future<void> fetchSalespersons() async {
    try {
      final response = await http.get(Uri.parse('https://sona-medico-backend.onrender.com/api/v1/salespeople'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          salespersons = data.map((e) => e['name'].toString()).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load salespersons');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching salespersons: $e')),
      );
    }
  }

  void createOrder() {
    if (selectedSalesperson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a salesperson')),
      );
      return;
    }

    // Simulate saving order
    print("Order Created!");
    print("Salesperson: $selectedSalesperson");
    print("Total Qty: ${widget.totalQuantity}");
    print("Total Price: ₹${widget.totalPrice}");
    print("Items: ${widget.cart}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order created successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Salesperson'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? const Center(child: Text('Failed to load salespersons'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Salesperson',
                border: OutlineInputBorder(),
              ),
              value: selectedSalesperson,
              items: salespersons
                  .map((sp) => DropdownMenuItem(value: sp, child: Text(sp)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedSalesperson = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: createOrder,
              icon: const Icon(Icons.save),
              label: const Text('Create Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
