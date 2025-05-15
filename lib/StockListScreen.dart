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

  Future<void> addToCartAPI(Map<String, dynamic> product, String salespersonId, String salespersonName) async {
    const String apiUrl = 'https://sona-medico-backend.onrender.com/api/v1/createOrder'; // Replace with actual URL

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerName': 'Shubham Kumar',  // You can retrieve the customer's name from the app's state
          'customerPhone': '9097989707',  // Get the phone number from the app's state
          'salespersonId': salespersonId,
          'salespersonName': salespersonName,
          'products': [product],  // Assuming product is a single product object
        }),
      );

      print("Response Status,${response.statusCode}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item added to cart")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add item to cart")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // final customerData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    // print("customerData,${customerData}");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Details"),
        backgroundColor: Colors.blue,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(
                        cart: cart,
                        removeItem: (index) {
                          setState(() => cart.removeAt(index));
                        },
                      ),
                    ),
                  );
                },
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 6,
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
        ],
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
                                Text("Image Link: ${item.imageLink}"),
                                Text("MRP: ${item.mrp}"),
                                const SizedBox(height: 4),
                                // Quantity Selector
                                Text("Warehouse → Ls: ${item.whLooseQty} | Pk: ${item.whPackQty}"),
                                Text("Branch → Ls: ${item.brLooseQty} | Pk: ${item.brPackQty}"),
                                // In the list view item builder, you can check the available stock and update the UI accordingly
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
                                        final maxQty = item.whLooseQty + item.whPackQty;
                                        if (selectedQty < maxQty) {
                                          setState(() {
                                            selectedQuantities[item.itemCode] = selectedQty + 1;
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Not enough stock available')),
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
                                          // Check if already in cart, update quantity
                                          final existingIndex = cart.indexWhere((p) => p['id'] == product['id']);
                                          if (existingIndex != -1) {
                                            cart[existingIndex]['quantity'] += selectedQty;
                                          } else {
                                            cart.add(product);
                                          }
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Item added to cart")),
                                        );
                                      }
                                          : null,
                                      icon: const Icon(Icons.add_shopping_cart),
                                      label: const Text("Add to Cart"),
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
