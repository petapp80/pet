import 'package:flutter/material.dart';

class ProductCartScreen extends StatefulWidget {
  const ProductCartScreen({super.key});

  @override
  State<ProductCartScreen> createState() => _ProductCartScreenState();
}

class _ProductCartScreenState extends State<ProductCartScreen> {
  bool isOngoingSelected =
      true; // Track the selected tab (Ongoing or Completed)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Cart'),
        backgroundColor: Colors.teal, // AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Row with Ongoing and Completed Text inside rounded box
            Row(
              children: [
                _buildTabText('Ongoing', isOngoingSelected),
                const SizedBox(width: 16),
                _buildTabText('Completed', !isOngoingSelected),
              ],
            ),
            const SizedBox(height: 16),

            // Display content based on selected tab (Ongoing or Completed)
            if (isOngoingSelected) ...[
              // Ongoing Cart Section
              _buildOngoingCard(),
              _buildOngoingCard(), // Add another ongoing card for demonstration
            ] else ...[
              // Completed Cart Section
              _buildCompletedCard(),
              _buildCompletedCard(), // Add another completed card for demonstration
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabText(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isOngoingSelected =
              text == 'Ongoing'; // Toggle between Ongoing/Completed
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.teal : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildOngoingCard() {
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
              "asset/image/dog1.png", // Sample image for ongoing product
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
              "Ongoing Product Title",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              "Description for the ongoing product goes here. You can provide details about the order.",
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
              children: [
                IconButton(
                  onPressed: () {
                    // Handle the action for this product (e.g., remove from cart)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Removed from ongoing cart."),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.remove_shopping_cart),
                  color: Colors.red,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // Handle the action for this product (e.g., mark as completed)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Marked as completed."),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  color: Colors.green,
                ),
                const Spacer(),
                // These icons will only be visible in Ongoing section
                IconButton(
                  onPressed: () {
                    // Share the product details
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Sharing this product..."),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  color: Colors.blue,
                ),
                IconButton(
                  onPressed: () {
                    // Handle the message action for this product
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Message for this product..."),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message_outlined),
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard() {
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
              "asset/image/dog1.png", // Sample image for completed product
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
              "Completed Product Title",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              "Description for the completed product goes here. You can provide details about the completed order.",
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
              children: [
                IconButton(
                  onPressed: () {
                    // Handle the action for this product (e.g., remove from cart)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Removed from completed cart."),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.remove_shopping_cart),
                  color: Colors.red,
                ),
                const Spacer(),
                // In the completed section, no share or message icons
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
