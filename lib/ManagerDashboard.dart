import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'create_order.dart';
import 'order_list.dart';
import 'signin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profilePage.dart';

class Managerdashboard extends StatelessWidget {
  final String username;

  const Managerdashboard({super.key, required this.username});

  Future<void> logout(BuildContext context) async {
    try {
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

      final response = await http.post(
        Uri.parse('https://sona-medico-backend.onrender.com/api/v1/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await prefs.remove('token');

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Signin()),
              (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to log out at the moment. Please try again shortly.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          )

      );
    }
  }

  void _navigateTo(String destination, BuildContext context) {
    Widget page;
    switch (destination) {
      case 'create_order':
        page = const CreateOrderScreen();
        break;
      case 'view_orders':
        page = const OrderListScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.blue.shade50,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.admin_panel_settings, size: 40),
                const SizedBox(height: 10),
                Text("Admin: $username"),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Create Order"),
            onTap: () => _navigateTo('create_order', context),
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text("View Orders"),
            onTap: () => _navigateTo('view_orders', context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () => logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4.0), // Smaller padding for compact design
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.blue), // Smaller icon size
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), // Smaller text size
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuButton<String> _buildMobileMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'logout') {
          logout(context);
        } else {
          _navigateTo(value, context);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'create_order', child: Text("Create Order")),
        const PopupMenuItem(value: 'view_orders', child: Text("View Orders")),
        const PopupMenuItem(value: 'logout', child: Text("Logout")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Dashboard"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide) _buildSidebar(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Smaller padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user, color: Colors.blueAccent, size: 24), // smaller icon
                  const SizedBox(width: 8),
                  Text(
                    "Welcome, $username",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8), // Smaller gap
                  // Create a matrix-like grid layout
                  GridView.count(
                    crossAxisCount: 2, // 3 columns to form a matrix
                    crossAxisSpacing: 10, // Reduced spacing between columns
                    mainAxisSpacing: 10, // Reduced spacing between rows
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(), // Disable scrolling in grid
                    children: [
                      _buildFeatureCard('Create Order', Icons.add, () {
                        _navigateTo('create_order', context);
                      }),
                      _buildFeatureCard('View Orders', Icons.view_list, () {
                        _navigateTo('view_orders', context);
                      }),
                      // _buildFeatureCard('Manage Orders', Icons.manage_accounts, () {
                      //   // Add navigation or function
                      // }),
                      // _buildFeatureCard('Reports', Icons.report, () {
                      //   // Add navigation or function
                      // }),
                      // _buildFeatureCard('Settings', Icons.settings, () {
                      //   // Add navigation or function
                      // }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Home tapped')),
              );
              break;
            case 1:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications tapped')),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(username: username),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}
