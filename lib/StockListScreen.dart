import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cartPage.dart';

// Model class for stock item
class StockItem {
  final String itemCode_csv;
  final String itemCode;
  final String itemName;
  final String packing;
  final int qtyPerPack;
  final String group;
  final String manufacturer;
  final String schedule;
  final String content;
  final String storage;
  final String imageLink;
  final double mrp;
  final int brPackQty;
  final int brLooseQty;
  final int whPackQty;
  final int whLooseQty;

  StockItem({
    required this.itemCode_csv,
    required this.itemCode,
    required this.itemName,
    required this.packing,
    required this.qtyPerPack,
    required this.group,
    required this.manufacturer,
    required this.schedule,
    required this.content,
    required this.storage,
    required this.imageLink,
    required this.mrp,
    required this.brPackQty,
    required this.brLooseQty,
    required this.whPackQty,
    required this.whLooseQty,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    final closingStock = json['ClosingStock'] ?? {};
    final brStock = closingStock['BR'] ?? {};
    final whStock = closingStock['WH'] ?? {};

    return StockItem(
      itemCode_csv: json['Item Code-CSV'] ?? '',
      itemCode: json['ItemCode'] ?? '',
      itemName: json['ItemName'] ?? '',
      packing: json['Packing'] ?? '',
      qtyPerPack: json['QtyPerPack'] ?? 0,
      group: json['Group'] ?? '',
      manufacturer: json['Manufacturer'] ?? '',
      schedule: json['Schedule'] ?? '',
      content: json['Content'] ?? '',
      storage: json['Storage'] ?? '',
      imageLink: json['ImageLink'] ?? '',
      mrp: json['MRP']?.toDouble() ?? 0.0,
      brPackQty: brStock['Pack'] ?? 0,
      brLooseQty: brStock['Loose'] ?? 0,
      whPackQty: whStock['Pack'] ?? 0,
      whLooseQty: whStock['Loose'] ?? 0,
    );
  }
}

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  late Future<List<StockItem>> stockFuture;
  List<StockItem> allStockItems = [];
  List<StockItem> filteredItems = [];
  List<Map<String, dynamic>> cart = [];
  final TextEditingController _searchController = TextEditingController();

  Map<String, int> selectedQuantities = {};

  @override
  void initState() {
    super.initState();
    stockFuture = fetchStockItems();
  }

  Future<List<StockItem>> fetchStockItems() async {
    try {
      final response = await http.get(
        Uri.parse("https://sona-medico-backend.onrender.com/api/v1/stockProducts"),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> jsonData = decoded is List ? decoded : decoded['data'];

        final stockList = jsonData.map((item) => StockItem.fromJson(item)).toList();
        stockList.sort((a, b) => a.itemName.compareTo(b.itemName));

        setState(() {
          allStockItems = stockList;
          filteredItems = stockList;
          for (var item in stockList) {
            selectedQuantities[item.itemCode] = 0;
          }
        });

        return stockList;
      } else {
        throw Exception('Failed to load stock data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  void filterStockItems(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredItems = allStockItems.where((item) {
        final name = item.itemName.toLowerCase();
        final code = item.itemCode.toLowerCase();
        final category = item.group.toLowerCase();
        final content = item.content.toLowerCase();
        final mfg = item.manufacturer.toLowerCase();

        return name.contains(lowerQuery) ||
            code.contains(lowerQuery) ||
            category.contains(lowerQuery) ||
            content.contains(lowerQuery) ||
            mfg.contains((lowerQuery));
      }).toList();
    });
  }

  Color getCardColor(String? schedule) {
    switch (schedule?.toUpperCase()) {
      case 'NARCOTIC':
        return Colors.red.shade100;
      case 'SCHEDULE H1 DRUGS':
        return Colors.orange.shade100;
      case 'NO4':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  // Future<bool> updateStockQuantity(String itemCode, int newQty) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('https://sona-medico-backend.onrender.com/api/v1/update-stock/$itemCode'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         'itemCode': itemCode,
  //         'newQuantity': newQty,
  //       }),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       return true;
  //     } else {
  //       print('Failed to update stock: ${response.body}');
  //       return false;
  //     }
  //   } catch (e) {
  //     print('Error updating stock: $e');
  //     return false;
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    final customerData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    // final customerData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final phoneNumber = customerData['phone'] ?? '';
    final showCartControls = phoneNumber.toString().isNotEmpty;
    print("Customer Data: $customerData");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Details"),
        backgroundColor: Colors.blue,
        actions: showCartControls
            ? [
          Stack(
            children: [
              IconButton(
                iconSize: 38.0,
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(
                        cart: cart, // pass reference
                        customerData: customerData,
                      ),
                    ),
                  );
                },
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 10,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      '${cart.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          )
        ]
            : [],
      ),

      body: FutureBuilder<List<StockItem>>(
        future: stockFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by name, code, content, MFG, category...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: filterStockItems,
                ),
              ),
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(child: Text('No matching stock found.'))
                    : ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final selectedQty = selectedQuantities[item.itemCode] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: getCardColor(item.schedule),
                      child: ExpansionTile(
                        leading: const Icon(Icons.inventory_2_rounded, color: Colors.green),
                        title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("MFG: ${item.manufacturer}"),
                            Text("Total Qty → Ls: ${item.brLooseQty + item.whLooseQty} | Pk: ${item.brPackQty + item.whPackQty}"),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("CSV Code: ${item.itemCode_csv}"),
                                Text("Code: ${item.itemCode}"),
                                Text("Category: ${item.group}"),
                                Text("Content: ${item.content}"),
                                Text("Storage: ${item.storage}"),
                                Text("Schedule: ${item.schedule}"),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Image: "),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Image.network(item.imageLink),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: const Text("Close"),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          item.imageLink,
                                          height: 50,
                                          width: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image, size: 50),
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const SizedBox(
                                              height: 50,
                                              width: 50,
                                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                Text("MRP: ${item.mrp}"),
                                const SizedBox(height: 4),
                                // Quantity Selector
                                Text("Warehouse → Ls: ${item.whLooseQty} | Pk: ${item.whPackQty}"),
                                Text("Branch → Ls: ${item.brLooseQty} | Pk: ${item.brPackQty}"),
                                // In the list view item builder, you can check the available stock and update the UI accordingly

                                if (showCartControls)
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            if (selectedQty > 0) {
                                              selectedQuantities[item.itemCode] = selectedQty - 1;
                                            }
                                          });
                                        },
                                        icon: const Icon(Icons.remove_circle_outline),
                                      ),
                                      Text('$selectedQty', style: const TextStyle(fontSize: 16)),
                                      IconButton(
                                        onPressed: () {
                                          final maxQty = item.brLooseQty + item.whLooseQty + item.brPackQty + item.whPackQty;
                                          if (selectedQty < maxQty) {
                                            setState(() {
                                              selectedQuantities[item.itemCode] = selectedQty + 1;
                                            });
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Insufficient stock available for this item.',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                                backgroundColor: Colors.red,
                                                behavior: SnackBarBehavior.floating,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.add_circle_outline),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        onPressed: selectedQty > 0
                                            ? () {
                                          final product = {
                                            "id": item.itemCode,
                                            "title": item.itemName,
                                            "price": item.mrp,
                                            "quantity": selectedQty,
                                            "image": item.imageLink,
                                          };

                                          setState(() {
                                            final existingIndex = cart.indexWhere((p) => p['id'] == product['id']);
                                            if (existingIndex != -1) {
                                              cart[existingIndex]['quantity'] = selectedQty; // update quantity
                                            } else {
                                              cart.add(product);
                                            }
                                          });

                                          // final bool success = await updateStockQuantity(item.itemCode, newQty);
                                          //
                                          //
                                          // if (success) {
                                          //   ScaffoldMessenger.of(context).showSnackBar(
                                          //     const SnackBar(content: Text("Item added to cart and stock updated")),
                                          //   );
                                          //   // Optionally update UI state to reflect new stock quantities
                                          //   setState(() {
                                          //     // Update your item's quantities accordingly here, if you hold it locally
                                          //     item.brLooseQty = 0; // or update accordingly
                                          //     item.whLooseQty = 0;  // for example purpose
                                          //     // Or refetch stock data if needed
                                          //   });
                                          // } else {
                                          //   ScaffoldMessenger.of(context).showSnackBar(
                                          //     const SnackBar(content: Text("Failed to update stock")),
                                          //   );
                                          // }

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Item successfully added.",
                                                style: TextStyle(color: Colors.white),
                                              ),
                                              backgroundColor: Colors.green,
                                              behavior: SnackBarBehavior.floating,
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                            : null,
                                        icon: const Icon(Icons.add_shopping_cart),
                                        label: const Text("Add"),
                                      ),
                                    ],
                                  )


                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
