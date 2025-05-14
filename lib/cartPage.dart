import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  final List<Map<String, dynamic>> cart;
  final void Function(int index) removeItem;

  const CartPage({Key? key, required this.cart, required this.removeItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int totalQuantity = cart.fold(0, (sum, item) => sum + (item['quantity'] as int));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: cart.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : ListView.builder(
        itemCount: cart.length,
        itemBuilder: (context, index) {
          final item = cart[index];
          return ListTile(
            leading: Image.network(
              item['image'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(item['title']),
            subtitle: Text("Qty: ${item['quantity']}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => removeItem(index),
            ),
          );
        },
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Total Items: ${cart.length} | Total Quantity: $totalQuantity",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
