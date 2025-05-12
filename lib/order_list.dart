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
    print("User Asscess ROLE, $role");
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
        const SnackBar(content: Text('Unauthorized: Token not found')),
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
        const SnackBar(content: Text('Failed to fetch orders')),
      );
    }
  }

  // Previous

  // Future<void> fetchOrders() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');
  //   if (token == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Unauthorized: Token not found')),
  //     );
  //     return;
  //   }
  //
  //   final response = await http.get(
  //     Uri.parse('http://192.168.29.253:3000/api/v1/viewOrders'),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     setState(() {
  //       orders = data['orders'];
  //     });
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to fetch orders')),
  //     );
  //   }
  // }

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
        const SnackBar(content: Text('Order deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete order')),
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
    productNameController.text = order['productName'] ?? '';
    customerNameController.text = order['customerName'] ?? '';
    customerPhoneController.text = order['customerPhone'] ?? '';
    quantityController.text = order['quantity'].toString();
    priceController.text = order['price'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Order"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productNameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: customerNameController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            TextField(
              controller: customerPhoneController,
              decoration: const InputDecoration(labelText: 'Customer Phone'),
            ),
            TextField(
              controller: quantityController,
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
              _updateOrder(order['id'], quantityController.text, priceController.text);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrder(String id, String quantity, String price) async {
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
        'productName': productNameController.text,
        'customerName': customerNameController.text,
        'customerPhone':customerPhoneController.text,
        'quantity': int.tryParse(quantity) ?? 0,
        'price': int.tryParse(price) ?? 0,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order updated successfully')),
      );
      fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order')),
      );
    }
  }

  // Future<void> _markReadyForDelivery(String id) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');
  //   final role = prefs.getString('role');
  //   if (token == null) return;
  //
  //   // Change the order status based on the role and current status
  //   String newStatus;
  //   if (role == 'salesperson') {
  //     newStatus = 'Ready for Delivery'; // For salesperson, mark it ready for delivery
  //   } else if (role == 'delivery') {
  //     newStatus = 'Delivered'; // For delivery, mark it as delivered after confirming
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Unknown role or invalid status')),
  //     );
  //     return;
  //   }
  //
  //   final response = await http.put(
  //     Uri.parse('http://192.168.29.253:3000/api/v1/editOrder/$id'),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     },
  //     body: jsonEncode({
  //       'status': newStatus,
  //       'deliveryAssignedToId': selectedDeliveryPerson, // Ensure this is set correctly
  //     }),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Order marked as Ready for Delivery')),
  //     );
  //
  //     // Call fetchOrders after updating status to reflect changes on the UI
  //     fetchOrders();
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to update status')),
  //     );
  //   }
  // }


  //   // Previous
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
        const SnackBar(content: Text('Unknown role or invalid status')),
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
        const SnackBar(content: Text('Order marked as Ready for Delivery')),
      );
      fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
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

  Future<void> _assignDeliveryPerson(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print("User Id,$id");
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unauthorized: Token not found')),
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
        'deliveryAssignedToId': selectedDeliveryPerson,
      }),
    );

    print("StatusCode,${response.statusCode}");
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order assigned to delivery person')),
      );
      fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign delivery person')),
      );
    }
  }

  void _callCustomer(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch dialer')),
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

          // ✅ Skip rendering hidden orders
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
                  Text("Product: ${order['productName'] ?? 'No Product'}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("Customer: ${order['customerName'] ?? 'N/A'}"),
                  Text("Quantity: ${order['quantity']}, Price: ₹${order['price']}"),
                  if (order['status'] != null) Text("Status: ${order['status']}"),
                  if (order['assignedTo'] != null) Text("Assigned To: ${order['assignedTo']}"),
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
                          onPressed: () {
                            fetchDeliveryPersons();
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Assign"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DropdownButton<String>(
                                      value: selectedDeliveryPerson,
                                      hint: const Text("Select Delivery Person"),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedDeliveryPerson = value;
                                        });
                                      },
                                      items: deliveryPersons.map((person) {
                                        return DropdownMenuItem<String>(
                                          value: person['id'],
                                          child: Text(person['fullName']),
                                        );
                                      }).toList(),
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
                                      _assignDeliveryPerson(order['id']);
                                    },
                                    child: const Text("Assign"),
                                  ),
                                ],
                              ),
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

  // Previous
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: const Text("Order List")),
  //     body: ListView.builder(
  //       itemCount: orders.length,
  //       itemBuilder: (_, index) {
  //         final order = orders[index];
  //         return Card(
  //           margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //           child: Padding(
  //             padding: const EdgeInsets.all(12.0),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text("Product: ${order['productName'] ?? 'No Product'}",
  //                     style: const TextStyle(fontWeight: FontWeight.bold)),
  //                 const SizedBox(height: 5),
  //                 Text("Customer: ${order['customerName'] ?? 'N/A'}"),
  //                 Text("Quantity: ${order['quantity']}, Price: ₹${order['price']}"),
  //                 if (order['status'] != null) Text("Status: ${order['status']}"),
  //                 if (order['assignedTo'] != null) Text("Assigned To: ${order['assignedTo']}"),
  //                 if (roles == 'delivery' && order['customerPhone'] != null) ...[
  //                   Row(
  //                     children: [
  //                       const Icon(Icons.phone_android),
  //                       const SizedBox(width: 8),
  //                       Text("Phone: ****${order['customerPhone'].toString().substring(order['customerPhone'].length - 4)}"),
  //                       IconButton(
  //                         icon: const Icon(Icons.call, color: Colors.green),
  //                         onPressed: () => _callCustomer(order['customerPhone']),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //
  //                 if (order['createdAt'] != null && order['createdAt']['_seconds'] != null)
  //                   Text("Created At: ${DateTime.fromMillisecondsSinceEpoch(order['createdAt']['_seconds'] * 1000)}"),
  //                 const SizedBox(height: 10),
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.end,
  //                   children: [
  //                     if (isAdmin) ...[
  //                       TextButton.icon(
  //                         onPressed: () => _editOrder(context, order),
  //                         icon: const Icon(Icons.edit, color: Colors.blue),
  //                         label: const Text("Edit"),
  //                       ),
  //                       const SizedBox(width: 8),
  //                       TextButton.icon(
  //                         onPressed: () => _confirmDelete(context, order['id'], index),
  //                         icon: const Icon(Icons.delete, color: Colors.red),
  //                         label: const Text("Delete"),
  //                       ),
  //                       // Show this button only when the status is "Ready for Delivery"
  //                       if (order['status'] == 'Ready for Delivery') ...[
  //                         ElevatedButton.icon(
  //                           onPressed: () {
  //                             fetchDeliveryPersons(); // Fetch delivery persons
  //                             showDialog(
  //                               context: context,
  //                               builder: (_) => AlertDialog(
  //                                 title: const Text("Assign"),
  //                                 content: Column(
  //                                   mainAxisSize: MainAxisSize.min,
  //                                   children: [
  //                                     DropdownButton<String>(
  //                                       value: selectedDeliveryPerson,
  //                                       hint: const Text("Select Delivery Person"),
  //                                       onChanged: (value) {
  //                                         setState(() {
  //                                           selectedDeliveryPerson = value;
  //                                         });
  //                                       },
  //                                       items: deliveryPersons.map((person) {
  //                                         return DropdownMenuItem<String>(
  //                                           value: person['id'],
  //                                           child: Text(person['fullName']),
  //                                         );
  //                                       }).toList(),
  //                                     ),
  //                                   ],
  //                                 ),
  //                                 actions: [
  //                                   TextButton(
  //                                     onPressed: () => Navigator.pop(context),
  //                                     child: const Text("Cancel"),
  //                                   ),
  //                                   ElevatedButton(
  //                                     onPressed: () {
  //                                       Navigator.pop(context);
  //                                       _assignDeliveryPerson(order['id']);
  //                                     },
  //                                     child: const Text("Assign"),
  //                                   ),
  //                                 ],
  //                               ),
  //                             );
  //                           },
  //                           icon: const Icon(Icons.delivery_dining),
  //                           label: const Text("Assign"),
  //                         ),
  //                       ],
  //                     ] else ...[
  //                       if (roles == 'salesperson' &&
  //                           (order['status'] == 'Shipped'))
  //                         ElevatedButton.icon(
  //                           onPressed: () => _markReadyForDelivery(order['id']),
  //                           icon: const Icon(Icons.check),
  //                           label: const Text("Confirm Order"),
  //                         ),
  //                       if (roles == 'delivery' && order['status'] == 'Ready for Delivery')
  //                         ElevatedButton.icon(
  //                           onPressed: () => _markReadyForDelivery(order['id']),
  //                           icon: const Icon(Icons.check),
  //                           label: const Text("Confirm Order"),
  //                         ),
  //
  //                     ],
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
}
