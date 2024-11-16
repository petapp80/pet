import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Sample data for cart items
  final List<Map<String, String>> _cartItems = [
    {
      "image": "asset/image/dog1.png",
      "text": "Suggestion 1",
      "description": "This is a description for Suggestion 1."
    },
    {
      "image": "asset/image/dog2.png",
      "text": "Suggestion 2",
      "description": "This is a description for Suggestion 2."
    },
    {
      "image": "asset/image/dog1.png",
      "text": "Suggestion 3",
      "description": "This is a description for Suggestion 3."
    },
    {
      "image": "asset/image/dog1.png",
      "text": "Suggestion 4",
      "description": "This is a description for Suggestion 4."
    },
  ];

  // Refresh function: to be triggered on pull-to-refresh
  Future<void> _handleRefresh() async {
    // Simulate a network delay (you can replace this with your actual data fetching logic)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      // You can update the cart items here after refreshing the data.
      // For now, we're just printing a message to indicate that refresh has occurred.
      print("Cart refreshed");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10.6),
          const Text(
            'My Cart',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh, // Triggered on pull-to-refresh
              child: ListView.builder(
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Image.asset(
                            item["image"]!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            item["text"]!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            item["description"]!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  final shareText =
                                      '${item["text"]}\n\n${item["description"]}';
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Share'),
                                      content:
                                          Text('You are sharing: \n$shareText'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.share_outlined),
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
