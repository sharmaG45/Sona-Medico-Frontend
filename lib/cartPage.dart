import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final void Function(int index) removeItem;
  final VoidCallback? clearCart;
  final Map<String, dynamic> customerData;

  const CartPage({
    Key? key,
    required this.cart,
    required this.removeItem,
    required this.customerData,
    this.clearCart,
  }) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _salespersonController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Map<String, String>> salespeople = [];
  String? selectedSalespersonId;
  String? selectedSalespersonName;

  bool isFetchingSalespeople = false;

  @override
  void dispose() {
    _salespersonController.dispose();
    super.dispose();
  }

  Future<void> fetchSalespeople() async {
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
        Uri.parse('https://sona-medico-backend.onrender.com/api/v1/salespeople'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final List<Map<String, String>> people = data.map((item) {
          return {
            'id': item['id']?.toString() ?? '',
            'fullName': item['fullName']?.toString() ?? 'Unnamed',
          };
        }).toList();

        setState(() {
          salespeople = people;
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
    await fetchSalespeople();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows the modal to take up more height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        if (salespeople.isEmpty) {
          return SizedBox(
            height: 150,
            child: Center(
              child: Text(
                'No salespeople available.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Text(
                'Select Salesperson',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),

              // Optional: Search Field to filter salespeople
              TextField(
                onChanged: (query) {
                  setState(() {
                    salespeople = salespeople
                        .where((person) => (person['fullName'] ?? '')
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                        .toList();
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search salespeople',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              const SizedBox(height: 12),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: salespeople.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey[300]),
                  itemBuilder: (context, index) {
                    final person = salespeople[index];
                    final isSelected = person['id'] == selectedSalespersonId;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        person['fullName'] ?? 'Unnamed',
                        style: TextStyle(
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.blueAccent : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.blueAccent)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedSalespersonId = person['id'];
                          selectedSalespersonName = person['fullName'];
                          _salespersonController.text =
                              person['fullName'] ?? '';
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }


  Future<void> _submitOrder() async {
    if (selectedSalespersonId == null || selectedSalespersonName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a salesperson')),
      );
      return;
    }

    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized: Token not found')),
        );
        return;
      }

      final url = Uri.parse('https://sona-medico-backend.onrender.com/api/v1/createOrder');

      final body = jsonEncode({
        "customerId": widget.customerData['id'],
        "customerName": widget.customerData['name'] ?? 'Unknown Customer',
        "customerPhone": widget.customerData['phone'] ?? '',
        "customerEmail": widget.customerData['email'] ?? '',
        "customerAddress": widget.customerData['address'] ?? '',
        "salespersonId": selectedSalespersonId,
        "salespersonName": selectedSalespersonName,
        "products": widget.cart.map((product) => {
          "id": product['id'],
          "title": product['title'],
          "price": product['price'],
          "quantity": product['quantity'],
          "image": product['image'],
        }).toList(),
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print("Response Data: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order submitted to $selectedSalespersonName!')),
        );

        // Clear the cart after successful order submission
        if (widget.clearCart != null) {
          widget.clearCart!();
        }

        _salespersonController.clear();
        setState(() {
          selectedSalespersonId = null;
          selectedSalespersonName = null;
        });
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = 0.0;
    int totalQuantity = 0;

    for (var item in widget.cart) {
      totalPrice += (item['price'] as num) * (item['quantity'] as int);
      totalQuantity += item['quantity'] as int;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: widget.cart.isNotEmpty && widget.clearCart != null
            ? [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Clear Cart",
            onPressed: () {
              // Confirm before clearing all items
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Cart'),
                  content: const Text('Are you sure you want to clear the entire cart?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.clearCart!();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          )
        ]
            : null,
      ),
      body: widget.cart.isEmpty
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("Your cart is empty", style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: widget.cart.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = widget.cart[index];
          final title = item['title'] ?? 'No Title';
          final quantity = item['quantity'] ?? 0;
          final price = item['price'] ?? 0.0;
          final subtotal = quantity * price;
          final imageUrl = item['imageUrl'] ?? item['image']; // sometimes image key may differ

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.shopping_bag, size: 40, color: Colors.blueAccent),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(
                "Qty: $quantity × ₹${price.toStringAsFixed(2)} = ₹${subtotal.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Remove item and notify parent
                  widget.removeItem(index);
                  // Optionally, you can call setState here if your widget holds local state for cart
                  // but since cart comes from parent, parent should rebuild this page
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.cart.isEmpty
          ? null
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Qty: $totalQuantity",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text("Total: ₹${totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
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
                    validator: (val) => selectedSalespersonId == null
                        ? 'Please select a salesperson'
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submitOrder();
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Submit Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
