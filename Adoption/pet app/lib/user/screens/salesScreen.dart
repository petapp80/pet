import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _selectedFilter = 'Today'; // Default filter option
  final List<Map<String, dynamic>> _salesData = [
    {
      'petName': 'Bulldog',
      'salesAmount': 100,
      'date': DateTime.now().subtract(const Duration(days: 1))
    },
    {
      'petName': 'Labrador',
      'salesAmount': 150,
      'date': DateTime.now().subtract(const Duration(days: 2))
    },
    {
      'petName': 'Poodle',
      'salesAmount': 200,
      'date': DateTime.now().subtract(const Duration(days: 7))
    },
    {
      'petName': 'German Shepherd',
      'salesAmount': 250,
      'date': DateTime.now().subtract(const Duration(days: 15))
    },
  ];

  List<Map<String, dynamic>> get filteredSales {
    DateTime now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return _salesData
            .where((sale) =>
                sale['date'].day == now.day &&
                sale['date'].month == now.month &&
                sale['date'].year == now.year)
            .toList();
      case 'This Week':
        DateTime startOfWeek = now.subtract(
            Duration(days: now.weekday - 1)); // Get the start of the week
        return _salesData
            .where((sale) => sale['date'].isAfter(startOfWeek))
            .toList();
      case 'This Month':
        return _salesData
            .where((sale) =>
                sale['date'].month == now.month &&
                sale['date'].year == now.year)
            .toList();
      case 'This Year':
        return _salesData
            .where((sale) => sale['date'].year == now.year)
            .toList();
      default:
        return _salesData;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Pet Sales Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Section
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedFilter,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFilter = newValue!;
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
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Add more search functionality here if needed
                    print('Searching...');
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
            // Chart Section (FL Chart)
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: filteredSales.map((sale) {
                    int index = filteredSales.indexOf(sale);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: sale['salesAmount'].toDouble(),
                          color: Colors.blue,
                          width: 16,
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= filteredSales.length ||
                              value.toInt() < 0) {
                            return const SizedBox.shrink();
                          }
                          return Transform.rotate(
                            angle: -0.3,
                            child: Text(
                              filteredSales[value.toInt()]['petName'],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Sales List Section
            const Text('Sales Data:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      title: Text(sale['petName']),
                      subtitle: Text('Sales: \$${sale['salesAmount']}'),
                      trailing: Text(
                          '${sale['date'].day}/${sale['date'].month}/${sale['date'].year}'),
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
