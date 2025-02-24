import 'package:flutter/material.dart';
import 'package:PetApp/user/screens/chatDetailScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

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
  String _petType = '';
  bool _isLoading = false;
  bool _showLicenseImage = false;
  bool _showVaccinationImage = false;
  String? _selectedPlace;
  List<String> _places = [];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpayPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onRazorpayExternalWallet);
    _fetchPlaces();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchPlaces() async {
    final doc = await FirebaseFirestore.instance
        .collection(widget.data['collection'])
        .doc(widget.data['id'])
        .get();
    final data = doc.data();
    if (data != null && data.containsKey('places')) {
      setState(() {
        _places = List<String>.from(data['places']);
      });
    }
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

    var priceString = docData?['price'] ?? '100';
    var amountString = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
    var amount = double.tryParse(amountString) ??
        100.0; // Default to 100 if parsing fails
    amount *= 100; // converting to paise as Razorpay expects amount in paise

    var options = {
      'key': 'rzp_test_D5Vh3hyi1gRBV0',
      'amount': amount,
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

  void _checkAndHandleCOD(
      BuildContext context, Map<String, dynamic> data, String field) async {
    if (data['collection'] == 'Veterinary')
      return; // Prevent COD for Veterinary collection

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final ownerDocRef = FirebaseFirestore.instance
        .collection('user')
        .doc(data['userId'])
        .collection('OwnerCollection')
        .doc(data['id']);
    final ownerDoc = await ownerDocRef.get();
    final ownerDocData = ownerDoc.data();
    final docRef = FirebaseFirestore.instance
        .collection(data['collection'])
        .doc(data['id']);
    final doc = await docRef.get();
    final docData = doc.data();
    final String fieldToUpdate =
        data['collection'] == 'Veterinary' ? 'appointments' : 'quantity';
    final int currentFieldCount =
        int.tryParse(docData?[fieldToUpdate]?.toString() ?? '0') ?? 0;
    final int ownerFieldCount =
        int.tryParse(ownerDocData?[fieldToUpdate]?.toString() ?? '0') ?? 0;

    if (currentFieldCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${field == "quantity" ? "Quantity" : "Appointment"} not available')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (currentFieldCount > 0) {
      await docRef.update({
        fieldToUpdate: currentFieldCount - 1,
      });
      print('Document Updated in Firestore');

      if (ownerFieldCount > 0) {
        await ownerDocRef.update({
          fieldToUpdate: ownerFieldCount - 1,
        });
        print('Owner Document Updated in Firestore');
      }

      final userDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('CartList')
          .doc(data['id']);
      await userDocRef.set({
        'status': 'ongoing',
        'id': data['id'],
        'text': data['text'],
        'description': data['description'],
        'image': data['image'],
        'profileImage': data['profileImage'],
        'profileName': data['profileName'],
        'userId': data['userId'],
        'published': data['published'],
        'location': data['location'],
        'paymentMethod': 'COD', // Add COD field
      });
      print('CartList Updated for User');

      final customerData = {
        'customerId': FirebaseAuth.instance.currentUser?.uid,
        'status': 'ongoing',
        'id': data['id'],
        'type': data['collection'],
        'paymentMethod': 'COD', // Add COD field
      };

      if (data['collection'] == 'Veterinary') {
        customerData['type of pet'] = _petType;
        customerData['place'] = _selectedPlace;
      }

      final sellerDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc(data['userId'])
          .collection('customers')
          .doc(); // Create a new document for each customer

      await sellerDocRef.set(customerData);

      print('Customer Info Created in Firestore');

      // Create a document in the Payments collection
      final paymentsDocRef =
          FirebaseFirestore.instance.collection('Payments').doc();
      final paymentData = {
        'id': data['id'],
        'type': data['collection'],
        'amount': docData?['price'],
        'time': FieldValue.serverTimestamp(),
        'paymentMethod': 'COD', // Add COD field
      };

      if (data['collection'] == 'Veterinary') {
        paymentData['place'] = _selectedPlace;
      }

      await paymentsDocRef.set(paymentData);

      // Update the quantity in the subcollection of the user
      final userSubcollectionRef = FirebaseFirestore.instance
          .collection('user')
          .doc(data['userId'])
          .collection(data['collection'])
          .doc(data['id']);
      final userSubcollectionDoc = await userSubcollectionRef.get();
      final userSubcollectionData = userSubcollectionDoc.data();
      final int userSubcollectionFieldCount = int.tryParse(
              userSubcollectionData?[fieldToUpdate]?.toString() ?? '0') ??
          0;

      if (userSubcollectionFieldCount > 0) {
        await userSubcollectionRef.update({
          fieldToUpdate: userSubcollectionFieldCount - 1,
        });
        print('User Subcollection Document Updated in Firestore');
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('COD Purchase successful')),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onRazorpayPaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success Callback Triggered');
    setState(() {
      _isLoading = true;
    });
    final String ownerId = widget.data['userId'];
    final ownerDocRef = FirebaseFirestore.instance
        .collection('user')
        .doc(ownerId)
        .collection('OwnerCollection')
        .doc(widget.data['id']);
    final docRef = FirebaseFirestore.instance
        .collection(widget.data['collection'])
        .doc(widget.data['id']);
    final ownerDoc = await ownerDocRef.get();
    final ownerDocData = ownerDoc.data();
    final doc = await docRef.get();
    final docData = doc.data();
    final String field =
        widget.data['collection'] == 'Veterinary' ? 'appointments' : 'quantity';
    final int currentFieldCount =
        int.tryParse(docData?[field]?.toString() ?? '0') ?? 0;
    final int ownerFieldCount =
        int.tryParse(ownerDocData?[field]?.toString() ?? '0') ?? 0;

    if (currentFieldCount > 0) {
      await docRef.update({
        field: currentFieldCount - 1,
      });
      print('Document Updated in Firestore');

      if (ownerFieldCount > 0) {
        await ownerDocRef.update({
          field: ownerFieldCount - 1,
        });
        print('Owner Document Updated in Firestore');
      }

      final userDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('CartList')
          .doc(widget.data['id']);
      await userDocRef.set({
        'status': 'ongoing',
        'id': widget.data['id'],
        'text': widget.data['text'],
        'description': widget.data['description'],
        'image': widget.data['image'],
        'profileImage': widget.data['profileImage'],
        'profileName': widget.data['profileName'],
        'userId': widget.data['userId'],
        'published': widget.data['published'],
        'location': widget.data['location'],
        'paymentMethod': 'Razorpay', // Default field for payment method
        'place': _selectedPlace, // Store the selected place
      });
      print('CartList Updated for User');

      final customerData = {
        'customerId': FirebaseAuth.instance.currentUser?.uid,
        'status': 'ongoing',
        'id': widget.data['id'],
        'type': widget.data['collection'],
        'paymentMethod': 'Razorpay', // Default field for payment method
        if (widget.data['collection'] == 'Veterinary') 'type of pet': _petType,
        if (widget.data['collection'] == 'Veterinary') 'place': _selectedPlace,
      };

      final sellerDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc(ownerId)
          .collection('customers')
          .doc(); // Create a new document for each customer

      await sellerDocRef.set(customerData);

      print('Customer Info Created in Firestore');

      // Update the quantity in the subcollection of the seller
      final sellerOwnerDocRef = FirebaseFirestore.instance
          .collection('user')
          .doc(ownerId)
          .collection('OwnerCollection')
          .doc(widget.data['id']);
      final sellerOwnerDoc = await sellerOwnerDocRef.get();
      final sellerOwnerDocData = sellerOwnerDoc.data();
      final int sellerOwnerFieldCount =
          int.tryParse(sellerOwnerDocData?[field]?.toString() ?? '0') ?? 0;

      if (sellerOwnerFieldCount > 0) {
        await sellerOwnerDocRef.update({
          field: sellerOwnerFieldCount - 1,
        });
        print('Seller Owner Document Updated in Firestore');
      }

      // Create a document in the Payments collection
      final paymentsDocRef =
          FirebaseFirestore.instance.collection('Payments').doc();
      await paymentsDocRef.set({
        'id': widget.data['id'],
        'type': widget.data['collection'],
        'amount': docData?['price'],
        'time': FieldValue.serverTimestamp(),
        'paymentMethod': 'Razorpay', // Default field for payment method
        'place': _selectedPlace, // Store the selected place
      });

      // Update the quantity in the subcollection of the user
      final userSubcollectionRef = FirebaseFirestore.instance
          .collection('user')
          .doc(widget.data['userId'])
          .collection(widget.data['collection'])
          .doc(widget.data['id']);
      final userSubcollectionDoc = await userSubcollectionRef.get();
      final userSubcollectionData = userSubcollectionDoc.data();
      final int userSubcollectionFieldCount =
          int.tryParse(userSubcollectionData?[field]?.toString() ?? '0') ?? 0;

      if (userSubcollectionFieldCount > 0) {
        await userSubcollectionRef.update({
          field: userSubcollectionFieldCount - 1,
        });
        print('User Subcollection Document Updated in Firestore');
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful')),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
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

  void _promptPetType(BuildContext context, Function(String) onSubmit) {
    TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Pet Type'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: "Type of pet"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onSubmit(_controller.text);
                Navigator.of(context).pop();
                print('Prompting place selection');
                _promptPlace((selectedPlace) {
                  setState(() {
                    _selectedPlace = selectedPlace;
                  });
                  _checkAndInitiatePayment(
                      context, widget.data, 'appointments');
                });
              },
              child: const Text('Okay'),
            ),
          ],
        );
      },
    );
  }

  void _promptPlace(Function(String) onSubmit) async {
    await _fetchPlaces();
    if (!mounted) return; // Ensure the widget is still in the tree
    if (_places.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No available places')),
      );
      return;
    }

    print('Showing place selection dialog with places: $_places');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Place'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<String>(
                value: _selectedPlace,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPlace = newValue;
                  });
                },
                items: _places.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_selectedPlace != null) {
                  onSubmit(_selectedPlace!);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Okay'),
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
    bool showActions = widget.navigationSource == 'HomePage';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data['text'] ?? 'Detail'),
      ),
      body: _isLoading
          ? Stack(
              children: [
                Container(
                  color:
                      const Color.fromARGB(255, 237, 234, 234).withOpacity(0.6),
                ),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Lottie.asset('asset/image/loading.json'),
                  ),
                ),
              ],
            )
          : Padding(
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
                    if (isVeterinaryCollection &&
                        widget.data.containsKey('licenseCertificateUrl'))
                      Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showLicenseImage = !_showLicenseImage;
                              });
                            },
                            child: Text(_showLicenseImage
                                ? 'Hide License Certificate'
                                : 'Show License Certificate'),
                          ),
                          if (_showLicenseImage)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.network(
                                widget.data['licenseCertificateUrl'],
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      ),
                    if (isPetsCollection &&
                        widget.data.containsKey('vaccinationUrl'))
                      Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showVaccinationImage = !_showVaccinationImage;
                              });
                            },
                            child: Text(_showVaccinationImage
                                ? 'Hide Vaccination Record'
                                : 'Show Vaccination Record'),
                          ),
                          if (_showVaccinationImage)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.network(
                                widget.data['vaccinationUrl'],
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
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
                      'Published: ${widget.data['published'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.data['description'] ?? 'No description available',
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
                      _buildDetailRow(
                          'Availability', widget.data['availability']),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.data['location'] ?? 'Unknown location',
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              widget.data['profileImage'] != null &&
                                      widget.data['profileImage'].isNotEmpty &&
                                      !widget.data['profileImage']
                                          .startsWith('asset/')
                                  ? NetworkImage(widget.data['profileImage'])
                                  : const AssetImage(
                                          'asset/image/default_profile.png')
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
                    if (showActions)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailScreen(
                                        name: widget.data['profileName'],
                                        image: widget.data['profileImage'] !=
                                                    null &&
                                                widget.data['profileImage']
                                                    .isNotEmpty
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
                              const Text('Chat'),
                            ],
                          ),
                          if (isVeterinaryCollection)
                            Column(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _promptPetType(context, (petType) {
                                      setState(() {
                                        _petType = petType;
                                      });
                                    });
                                  },
                                  icon: const Icon(Icons.event_note_outlined),
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                const Text('Book Appointment'),
                              ],
                            )
                          else
                            Column(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _checkAndInitiatePayment(
                                        context, widget.data, 'quantity');
                                  },
                                  icon: const Icon(
                                      Icons.add_shopping_cart_outlined),
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                const Text('Add to Cart'),
                              ],
                            ),
                          if (!isVeterinaryCollection)
                            Column(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _checkAndHandleCOD(
                                        context, widget.data, 'quantity');
                                  },
                                  icon: const Icon(Icons.attach_money_outlined),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const Text('Cash on Delivery'),
                              ],
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (showActions)
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            addItemToCart(context, widget.data);
                          },
                          child: const Text('Add to Cart'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(String fieldName, dynamic fieldValue) {
    if (fieldValue == null || fieldValue.toString().isEmpty) {
      return const SizedBox.shrink();
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
          Expanded(
            child: Text(
              fieldValue.toString(),
              style: const TextStyle(
                fontSize: 16,
              ),
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
        'text': item['text'],
        'description': item['description'],
        'image': item['image'],
        'profileImage': item['profileImage'],
        'profileName': item['profileName'],
        'userId': item['userId'],
        'published': item['published'],
        'location': item['location'],
        'status': 'wishlist',
        'addedAt': FieldValue.serverTimestamp(),
        'place': _selectedPlace, // Store the selected place
      };

      await cartItemRef.set(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['text']} added to cart'),
          duration: const Duration(seconds: 1),
        ),
      );

      final customerData = {
        'customerId': userId,
        'status': 'ongoing',
        'id': item['id'],
        'type': item['collection'], // Added field type
        if (widget.data['collection'] == 'Veterinary') 'type of pet': _petType,
        if (widget.data['collection'] == 'Veterinary') 'place': _selectedPlace,
      };

      final sellerCustomerRef = FirebaseFirestore.instance
          .collection('user')
          .doc(item['userId'])
          .collection('customers')
          .doc(); // Create a new document for each customer

      await sellerCustomerRef.set(customerData);

      print('Customer Info Created in Firestore');
    }
  }
}
