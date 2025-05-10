import 'package:flutter/material.dart';
import 'signin.dart'; // Ensure correct path

class HomePage extends StatelessWidget {
  final String username;
  const HomePage({super.key, required this.username});

  void _showProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle, size: 60, color: Colors.indigo),
              const SizedBox(height: 10),
              Text("Logged in as", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 5),
              Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Signin()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.inventory, color: Colors.white),
            const SizedBox(width: 8),
            const Text("InvPro Dashboard"),
          ],
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => _showProfile(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Summary Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildCard("Products", "150", Icons.production_quantity_limits),
                buildCard("Stock", "12,000", Icons.store),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildCard("Orders", "320", Icons.shopping_cart),
                buildCard("Alerts", "5", Icons.warning_amber),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Activity
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  buildActivity("Added 10 new laptops to stock."),
                  buildActivity("Order #245 has been shipped."),
                  buildActivity("Low stock alert: Mouse Pads"),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.indigo,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget buildCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 36, color: Colors.indigo),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildActivity(String description) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.circle, color: Colors.indigo, size: 12),
        title: Text(description),
      ),
    );
  }
}
