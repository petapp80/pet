import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/screens/chatDetailScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String navigationSource;

  const DetailScreen({
    required this.data,
    required this.navigationSource,
    Key? key,
  }) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Razorpay _razorpay;
  String? _petItem;
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpayPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onRazorpayExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<String?> _getAvailableTimeSlot(String sellerId) async {
    final times = [
      "10:00",
      "10:30",
      "11:00",
      "11:30",
      "12:00",
      "12:30",
      "13:00",
      "13:30",
      "14:00",
      "14:30",
      "15:00",
      "15:30",
      "16:00",
      "16:30",
      "17:00"
    ];

    final sellerCustomerSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(sellerId)
        .collection('customers')
        .get();

    final List<String> allocatedTimes = [];
    for (var doc in sellerCustomerSnapshot.docs) {
      List<dynamic> customerInfo = doc.data()['customerInfo'] ?? [];
      for (var info in customerInfo) {
        allocatedTimes.add(info['time']);
      }
    }

    for (var time in times) {
      if (!allocatedTimes.contains(time)) {
        return time;
      }
    }

    return null; // No available time slots
  }

  void _checkAndInitiatePayment(
      BuildContext context, Map<String, dynamic> data, String field) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection(data['collection'])
        .doc(data['id'])
        .get();
    final docData = doc.data();
    final currentFieldCount =
        int.tryParse(docData?[field]?.toString() ?? '0') ?? 0;

    if (currentFieldCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${field == "quantity" ? "Quantity" : "Appointment"} not available')),
      );
      return;
    }

    // Check available time slots
    final availableTime = await _getAvailableTimeSlot(data['userId']);
    if (availableTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointments not available')),
      );
      return;
    }
    _selectedTime = availableTime;

    var options = {
      'key': 'rzp_test_D5Vh3hyi1gRBV0',
      'amount': 100,
      'name': 'Pet App',
      'description':
          'Payment for ${field == "quantity" ? "product" : "appointment"}',
      'prefill': {'contact': '8888888888', 'email': 'test@razorpay.com'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error opening Razorpay: $e');
    }
  }

  void _onRazorpayPaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success Callback Triggered');
    final docRef = FirebaseFirestore.instance
        .collection(widget.data['collection'])
        .doc(widget.data['id']);
    final doc = await docRef.get();
    final docData = doc.data();
    final String field =
        widget.data['collection'] == 'Veterinary' ? 'appointments' : 'quantity';
    final int currentFieldCount =
        int.tryParse(docData?[field]?.toString() ?? '0') ?? 0;

    if (currentFieldCount > 0) {
      await docRef.update({
        field: currentFieldCount - 1,
      });
      print('Document Updated in Firestore');

      final userDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('CartList')
          .doc(widget.data['id']);
      await userDocRef.set({
        'status': 'ongoing',
        'id': widget.data['id'],
        'time': _selectedTime, // Add the time field
      });
      print('CartList Updated for User');

      final String sellerId = widget.data['userId'];
      final sellerDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc(sellerId)
          .collection('customers')
          .doc(widget.data['id']);
      final customerData = {
        'customerId': FirebaseAuth.instance.currentUser?.uid,
        'status': 'ongoing',
        'type': widget.data['collection'] == 'pets' ? 'pet' : 'product',
        'id': widget.data['id'],
        'petItem': _petItem ?? '', // Add the petItem field
        'time': _selectedTime, // Add the time field
      };

      final sellerCustomerSnapshot = await sellerDocRef.get();

      if (sellerCustomerSnapshot.exists) {
        await sellerDocRef.update({
          'customerInfo': FieldValue.arrayUnion([customerData]),
        });
        print('Customer Info Updated in Firestore');
      } else {
        await sellerDocRef.set({
          'customerInfo': [customerData],
        });
        print('Customer Info Created in Firestore');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful')),
      );
    }
  }

  void _onRazorpayPaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _onRazorpayExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  void _showPetItemDialog(BuildContext context, String field) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Pet Item'),
          content: TextField(
            onChanged: (value) {
              _petItem = value;
            },
            decoration: InputDecoration(
              hintText: 'Pet Item',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkAndInitiatePayment(context, widget.data, field);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isVeterinaryCollection = widget.data['collection'] == 'Veterinary';
    bool isPetsCollection = widget.data['collection'] == 'pets';
    bool isProductsCollection = widget.data['collection'] == 'products';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data['text'] ?? 'Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.data['image'] != null &&
                  widget.data['image'].isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    widget.data['image'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                widget.data['text'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Published: ${widget.data['published']}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.data['description'] ?? 'No description',
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              if (isPetsCollection) ...[
                _buildDetailRow('Age', widget.data['age']),
                _buildDetailRow('Breed', widget.data['breed']),
                _buildDetailRow('Colour', widget.data['colour']),
                _buildDetailRow('Price', widget.data['price']),
                _buildDetailRow('Sex', widget.data['sex']),
                _buildDetailRow('Weight', widget.data['weight']),
              ],
              if (isProductsCollection) ...[
                _buildDetailRow('Price', widget.data['price']),
                _buildDetailRow('Quantity', widget.data['quantity']),
              ],
              if (isVeterinaryCollection) ...[
                _buildDetailRow('Experience', widget.data['experience']),
                _buildDetailRow('Price', widget.data['price']),
                _buildDetailRow('Availability', widget.data['availability']),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    widget.data['location'] ?? 'Unknown location',
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: widget.data['profileImage'] != null &&
                            widget.data['profileImage'].isNotEmpty
                        ? NetworkImage(widget.data['profileImage'])
                        : const AssetImage('asset/image/dog1.png')
                            as ImageProvider,
                    radius: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.data['profileName'] ?? 'Unknown user',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            name: widget.data['profileName'],
                            image: widget.data['profileImage'] != null &&
                                    widget.data['profileImage'].isNotEmpty
                                ? widget.data['profileImage']
                                : 'asset/image/default_profile.png',
                            navigationSource: 'DetailScreen',
                            userId: widget.data['userId'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message_outlined),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  if (isVeterinaryCollection)
                    IconButton(
                      onPressed: () {
                        _showPetItemDialog(context, 'appointments');
                      },
                      icon: const Icon(Icons.event_note_outlined),
                      color: Theme.of(context).colorScheme.secondary,
                    )
                  else
                    IconButton(
                      onPressed: () {
                        _checkAndInitiatePayment(
                            context, widget.data, 'quantity');
                      },
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String fieldName, dynamic fieldValue) {
    if (fieldValue == null || fieldValue.toString().isEmpty) {
      return SizedBox
          .shrink(); // Do not display anything if the field value is null or empty
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$fieldName: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            fieldValue.toString(),
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void addItemToCart(BuildContext context, Map<String, dynamic> item) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final cartItemRef = FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .collection('CartList')
        .doc(item['id']);

    final cartItemSnapshot = await cartItemRef.get();

    if (cartItemSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item is already in cart'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      final cartItem = {
        'id': item['id'],
        'collection': item['collection'],
        'image': item['image'],
        'text': item['text'],
        'description': item['description'],
        'location': item['location'],
        'published': item['published'],
        'profileName': item['profileName'],
        'addedAt': FieldValue.serverTimestamp(),
        'status': 'ongoing',
        'userId': item['userId'],
      };

      await cartItemRef.set(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['text']} added to cart'),
          duration: const Duration(seconds: 1),
        ),
      );

      final createdById = item['userId'];
      final customerData = {
        'customerId': userId,
        'status': 'ongoing',
        'type': item['collection'] == 'pets' ? 'pet' : 'product',
        'id': item['id'],
        'petItem': _petItem ?? '', // Add the petItem field
        'time': _selectedTime, // Add the time field
      };

      final sellerCustomerRef = FirebaseFirestore.instance
          .collection('user')
          .doc(createdById)
          .collection('customers')
          .doc(item['id']);

      final sellerCustomerSnapshot = await sellerCustomerRef.get();

      if (sellerCustomerSnapshot.exists) {
        await sellerCustomerRef.update({
          'customerInfo': FieldValue.arrayUnion([customerData]),
        });
      } else {
        await sellerCustomerRef.set({
          'customerInfo': [customerData],
        });
      }
    }
  }
}
