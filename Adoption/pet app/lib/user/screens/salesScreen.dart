import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _selectedFilter = 'Today'; // Default filter option
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _paymentsData = [];
  bool _isLoading = true; // Loading state

  List<Map<String, dynamic>> get filteredSales {
    DateTime now = DateTime.now();
    if (_selectedDate != null) {
      return _paymentsData
          .where((sale) =>
              sale['time'].toDate().day == _selectedDate!.day &&
              sale['time'].toDate().month == _selectedDate!.month &&
              sale['time'].toDate().year == _selectedDate!.year)
          .toList();
    }
    switch (_selectedFilter) {
      case 'Today':
        return _paymentsData
            .where((sale) =>
                sale['time'].toDate().day == now.day &&
                sale['time'].toDate().month == now.month &&
                sale['time'].toDate().year == now.year)
            .toList();
      case 'This Week':
        DateTime startOfWeek = now.subtract(
            Duration(days: now.weekday - 1)); // Get the start of the week
        return _paymentsData
            .where((sale) => sale['time'].toDate().isAfter(startOfWeek))
            .toList();
      case 'This Month':
        return _paymentsData
            .where((sale) =>
                sale['time'].toDate().month == now.month &&
                sale['time'].toDate().year == now.year)
            .toList();
      case 'This Year':
        return _paymentsData
            .where((sale) => sale['time'].toDate().year == now.year)
            .toList();
      default:
        return _paymentsData;
    }
  }

  double get totalSales {
    return filteredSales.fold(0, (sum, sale) {
      double amount = 0;
      if (sale['amount'] is num) {
        amount = (sale['amount'] as num).toDouble();
      } else if (sale['amount'] is String) {
        amount = double.tryParse(
                sale['amount'].replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0;
      }
      return sum + amount;
    });
  }

  Map<String, double> get salesByCollection {
    Map<String, double> sales = {'pets': 0, 'products': 0, 'Veterinary': 0};
    for (var sale in filteredSales) {
      double amount = 0;
      if (sale['amount'] is num) {
        amount = (sale['amount'] as num).toDouble();
      } else if (sale['amount'] is String) {
        amount = double.tryParse(
                sale['amount'].replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0;
      }
      sales[sale['type']] = (sales[sale['type']] ?? 0) + amount;
    }
    print("Sales by Collection: $sales");
    return sales;
  }

  @override
  void initState() {
    super.initState();
    _fetchPaymentsData();
  }

  Future<void> _fetchPaymentsData() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('Payments').get();
    List<Map<String, dynamic>> paymentsData = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['paymentMethod'] == 'COD' && data['status'] != 'completed') {
        continue; // Ignore this document
      }
      if (data['type'] == 'pets' || data['type'] == 'products') {
        var details = await getDocumentDetails(data['id'], data['type']);
        if (details != null) {
          data.addAll(details);
          paymentsData.add(data);
        }
      }
    }
    setState(() {
      _paymentsData = paymentsData;
      _isLoading = false; // Set loading state to false once data is loaded
    });
    print("Payments Data: $_paymentsData");
  }

  Future<Map<String, dynamic>?> getDocumentDetails(
      String id, String type) async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection(type).doc(id).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        if (type == 'pets') {
          return {
            'title': data['petType'],
            'description': data['about'],
          };
        } else if (type == 'products') {
          return {
            'title': data['productName'],
            'description': data['description'],
          };
        }
      }
    } catch (e) {
      print('Error fetching document details: $e');
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedFilter = ''; // Clear filter when a specific date is selected
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Sales Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(), // Show loading indicator
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Section
                  Row(
                    children: [
                      DropdownButton<String>(
                        value:
                            _selectedFilter.isEmpty ? 'Today' : _selectedFilter,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedFilter = newValue!;
                            _selectedDate =
                                null; // Clear selected date when a filter is selected
                          });
                        },
                        items: <String>[
                          'Today',
                          'This Week',
                          'This Month',
                          'This Year'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      const Spacer(),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // Pie Chart Section (FL Chart)
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: salesByCollection.entries.map((entry) {
                          return PieChartSectionData(
                            value: entry.value,
                            title:
                                '${entry.key} \n${entry.value.toStringAsFixed(2)}',
                            color: entry.key == 'pets'
                                ? Colors.blue
                                : entry.key == 'products'
                                    ? Colors.green
                                    : Colors.red,
                            radius: 50,
                          );
                        }).toList(),
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Total Sales Section
                  Text(
                    'Total Sales: \$${totalSales.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sales List Section
                  const Text(
                    'Sales Data:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredSales.length,
                      itemBuilder: (context, index) {
                        var sale = filteredSales[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text(sale['title'] ?? 'No title available'),
                            subtitle: Text(sale['description'] ??
                                'No description available'),
                            trailing: Text(
                              '${sale['time'].toDate().day}/${sale['time'].toDate().month}/${sale['time'].toDate().year}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
