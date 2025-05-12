import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Model class for stock item
class StockItem {
  final String itemCode;
  final String itemName;
  final String itemCategory;
  final String itemCategoryClass;
  final String itemCategoryHead;
  final String brand;
  final int brLsBalQty;
  final int brPkBalQty;
  final int whLsBalQty;
  final int whPkBalQty;
  final int totalLsBalQty;
  final int totalPkBalQty;

  StockItem({
    required this.itemCode,
    required this.itemName,
    required this.itemCategory,
    required this.itemCategoryClass,
    required this.itemCategoryHead,
    required this.brand,
    required this.brLsBalQty,
    required this.brPkBalQty,
    required this.whLsBalQty,
    required this.whPkBalQty,
    required this.totalLsBalQty,
    required this.totalPkBalQty,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      itemCategory: json['itemCategory'] ?? '',
      itemCategoryClass: json['itemCategoryClass'] ?? '',
      itemCategoryHead: json['itemCategoryHead'] ?? '',
      brand: json['brand'] ?? '',
      brLsBalQty: int.tryParse(json['brLsBalQty'].toString()) ?? 0,
      brPkBalQty: int.tryParse(json['brPkBalQty'].toString()) ?? 0,
      whLsBalQty: int.tryParse(json['whLsBalQty'].toString()) ?? 0,
      whPkBalQty: int.tryParse(json['whPkBalQty'].toString()) ?? 0,
      totalLsBalQty: int.tryParse(json['totalLsBalQty'].toString()) ?? 0,
      totalPkBalQty: int.tryParse(json['totalPkBalQty'].toString()) ?? 0,
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
      print("Raw response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Adjust depending on your API response structure
        final List<dynamic> jsonData =
        decoded is List ? decoded : decoded['data'];

        if (jsonData.isEmpty) {
          throw Exception('No stock data found in response.');
        }

        final stockList =
        jsonData.map((item) => StockItem.fromJson(item)).toList();
        print("Parsed items count: ${stockList.length}");
        return stockList;
      } else {
        throw Exception(
            'Failed to load stock data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Details"),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<List<StockItem>>(
        future: stockFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No stock data found.'));
          }

          final stockItems = snapshot.data!;

          return ListView.builder(
            itemCount: stockItems.length,
            itemBuilder: (context, index) {
              final item = stockItems[index];
              print("Rendering item: ${item.itemName}");

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Builder(
                  builder: (_) {
                    try {
                      return ListTile(
                        leading: const Icon(Icons.inventory_2_rounded,
                            color: Colors.green),
                        title: Text(
                          item.itemName,
                          style:
                          const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Code: ${item.itemCode}"),
                            Text("Category: ${item.itemCategory}"),
                            Text("Class: ${item.itemCategoryClass}"),
                            Text("Brand: ${item.brand}"),
                            Text(
                                "Total Ls Qty: ${item.totalLsBalQty} | Pk Qty: ${item.totalPkBalQty}"),
                          ],
                        ),
                      );
                    } catch (e) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Error rendering item: $e"),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
