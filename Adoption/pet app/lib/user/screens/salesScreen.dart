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
    // More data...
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

  // Function to create the chart data
  List<Map<String, dynamic>> _generateChartData() {
    return filteredSales
        .map((sale) => {
              'petName': sale['petName'],
              'salesAmount': sale['salesAmount'],
            })
        .toList();
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
                    // You can add more search functionality here if needed
                    print('Searching...');
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Chart Section (Custom Bar Chart)
            SizedBox(
              height: 250,
              child: CustomPaint(
                painter: SalesChartPainter(_generateChartData()),
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

class SalesChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  SalesChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.blue;

    double barWidth = size.width / data.length;
    double maxHeight = size.height;

    for (int i = 0; i < data.length; i++) {
      double barHeight = data[i]['salesAmount'] *
          (maxHeight / 250); // Scaling sales amount to fit the chart height
      double xPosition = i * barWidth;
      double yPosition = size.height - barHeight;

      // Draw each bar
      canvas.drawRect(
        Rect.fromLTWH(xPosition, yPosition, barWidth - 10, barHeight),
        paint,
      );

      // Draw labels at the bottom
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: data[i]['petName'],
          style: const TextStyle(color: Colors.black, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(
        canvas,
        Offset(xPosition + 5, size.height - 20),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
