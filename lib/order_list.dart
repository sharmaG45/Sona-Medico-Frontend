import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<dynamic> orders = [];
  bool isAdmin = false;

  TextEditingController productNameController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerPhoneController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  String? selectedDeliveryPerson;
  String? roles;
  List<dynamic> deliveryPersons = [];

  Set<String> hiddenOrderIds = {};

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    fetchOrders();

  }

  Future<void> fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    roles=role;
    print("User Asccess ROLE, $role");
    setState(() {
      isAdmin = role == 'admin';
    });
  }

  Future<void> fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role'); // Get the current user's role
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unauthorized access: Token not found. Please login again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final response = await http.get(
      Uri.parse('https://sona-medico-backend.onrender.com/api/v1/viewOrders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("Response Order List Data,${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        final allOrders = data['orders'];

        // Filter orders based on the user's role and status
        if (role == 'delivery') {
          // Delivery should not see "Delivered" orders
          orders = allOrders.where((order) => order['status'] != 'Delivered').toList();
        } else if (role == 'salesperson') {
          // Salesperson should not see "Ready for Delivery" orders
          orders = allOrders.where((order) => order['status'] != 'Ready for Delivery').toList();
        } else {
          // Admin can see all orders
          orders = allOrders;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch orders. Please try again later.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

    }
  }


  Future<void> deleteOrder(String id, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.delete(
      Uri.parse('https://sona-medico-backend.onrender.com/api/v1/deleteOrder/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        orders.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order deleted successfully.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete order. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

    }
  }

  void _confirmDelete(BuildContext context, String id, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteOrder(id, index);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _editOrder(BuildContext context, Map<String, dynamic> order) {
    customerNameController.text = order['customerName'] ?? '';
    customerPhoneController.text = order['customerPhone'] ?? '';

    for (var product in order['products']) {
      TextEditingController qtyController = TextEditingController(text: product['quantity'].toString());
      TextEditingController priceController = TextEditingController(text: product['price'].toString());

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Edit ${product['productName']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateSingleProductInOrder(
                  order['id'],
                  product['productId'],
                  int.tryParse(qtyController.text) ?? product['quantity'],
                  double.tryParse(priceController.text) ?? product['price'],
                );
              },
              child: const Text("Update Product"),
            ),
          ],
        ),
      );
    }
  }


  Future<void> _updateSingleProductInOrder( String id, String productId, int quantity, double price,) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.put(
      Uri.parse('https://sona-medico-backend.onrender.com/api/v1/editOrder/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'price': price,
      }),
    );

    print("Edit Order Response,${response.body}");
    print("Edit Order Response,${response.statusCode}");
    if (response.statusCode == 200) {
      print("Order updated successfully");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order updated successfully')),
      );
    } else {
      print("Failed to update order: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order: ${response.body}')),
      );
    }
  }

  Future<void> _markReadyForDelivery(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    if (token == null) return;


    // Change the order status based on the role and current status
    String newStatus;
    if (role == 'salesperson') {
      newStatus = 'Ready for Delivery'; // For salesperson, mark it ready for delivery
    } else if (role == 'delivery') {
      newStatus = 'Delivered'; // For delivery, mark it as delivered after confirming
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Unknown role or invalid status.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final response = await http.put(
      Uri.parse('https://sona-medico-backend.onrender.com/api/v1/editOrder/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': newStatus,
        'deliveryAssignedToId': selectedDeliveryPerson,
      }),

    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as Ready for Delivery!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

    }
  }

  Future<void> fetchDeliveryPersons() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unauthorized: Token not found')),
      );
      return;
    }
    final response = await http.get(
      Uri.parse('https://sona-medico-backend.onrender.com/api/v1/getDeliveryPersons'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        deliveryPersons = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch delivery persons')),
      );
    }
  }

  Future<void> _assignDeliveryPerson(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unauthorized: Token not found. Please log in again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );

      return;
    }

    try {
      final response = await http.put(
        Uri.parse('https://sona-medico-backend.onrender.com/api/v1/editOrder/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'deliveryAssignedToId': selectedDeliveryPerson,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order successfully assigned to delivery person.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

        await fetchOrders(); // Refresh the order list after assignment
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign delivery person: ${errorData['message'] ?? 'Unknown error occurred.'}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );

      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning delivery person: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );

    }
  }


  void _callCustomer(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch dialer'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order List")),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (_, index) {
          final order = orders[index];

          //  Skip rendering hidden orders
          if (hiddenOrderIds.contains(order['id'])) {
            return const SizedBox.shrink();
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Products:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List<Widget>.from((order['products'] as List).map((product) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        "${product['productName']} - Qty: ${product['quantity']}, Price: ₹${(product['price'] / 100).toStringAsFixed(2)}",
                      ),
                    );
                  })),

                  const SizedBox(height: 5),
                  Text("Customer Name: ${order['customerName'] ?? 'N/A'}"),
                  // Text("Customer Phone: ${order['customerPhone'] ?? 'N/A'}"),
                  // Text("Customer Email: ${order['customerEmail'] ?? 'N/A'}"),
                  Text("Customer Address: ${order['customerAddress'] ?? 'N/A'}"),
                  if (order['status'] != null) Text("Status: ${order['status']}"),
                  if (order['assignedToName'] != null) Text("Assigned Salesperson: ${order['assignedToName']}"),
                  if (roles == 'delivery' && order['customerPhone'] != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.phone_android),
                        const SizedBox(width: 8),
                        Text("Phone: ****${order['customerPhone'].toString().substring(order['customerPhone'].length - 4)}"),
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () => _callCustomer(order['customerPhone']),
                        ),
                      ],
                    ),
                  ],
                  if (order['createdAt'] != null && order['createdAt']['_seconds'] != null)
                    Text("Created At: ${DateTime.fromMillisecondsSinceEpoch(order['createdAt']['_seconds'] * 1000)}"),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Admins can Edit, Delete, and Assign
                      if (isAdmin) ...[
                        TextButton.icon(
                          onPressed: () => _editOrder(context, order),
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          label: const Text("Edit"),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _confirmDelete(context, order['id'], index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text("Delete"),
                        ),
                      ],

                      // Admins or Managers can Assign
                      if ((isAdmin || roles == 'manager') && order['status'] == 'Ready for Delivery') ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Show loading dialog while fetching delivery persons
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );

                            await fetchDeliveryPersons();

                            // Close loading dialog
                            if (context.mounted) Navigator.pop(context);

                            if (!context.mounted) return;

                            // Show assign dialog
                            showDialog(
                              context: context,
                              builder: (_) {
                                String? tempSelectedDeliveryPerson = selectedDeliveryPerson;

                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: const Text("Assign Delivery Person"),
                                      content: deliveryPersons.isEmpty
                                          ? const Text("No delivery persons available.")
                                          : DropdownButton<String>(
                                        value: tempSelectedDeliveryPerson,
                                        hint: const Text("Select Delivery Person"),
                                        isExpanded: true,
                                        onChanged: (value) {
                                          setState(() {
                                            tempSelectedDeliveryPerson = value;
                                          });
                                        },
                                        items: deliveryPersons.map((person) {
                                          return DropdownMenuItem<String>(
                                            value: person['id'],
                                            child: Text(person['fullName']),
                                          );
                                        }).toList(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: tempSelectedDeliveryPerson == null
                                              ? null
                                              : () {
                                            Navigator.pop(context);
                                            setState(() {
                                              selectedDeliveryPerson = tempSelectedDeliveryPerson;
                                            });
                                            _assignDeliveryPerson(order['id']);
                                          },
                                          child: const Text("Assign"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.delivery_dining),
                          label: const Text("Assign"),
                        ),
                      ],


                      // Salesperson and Delivery roles
                      if (roles == 'salesperson' && order['status'] == 'Shipped')
                        ElevatedButton.icon(
                          onPressed: () => _markReadyForDelivery(order['id']),
                          icon: const Icon(Icons.check),
                          label: const Text("Confirm Order"),
                        ),
                      if (roles == 'delivery' && order['status'] == 'Ready for Delivery')
                        ElevatedButton.icon(
                          onPressed: () => _markReadyForDelivery(order['id']),
                          icon: const Icon(Icons.check),
                          label: const Text("Confirm Order"),
                        ),
                    ],
                  )

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
