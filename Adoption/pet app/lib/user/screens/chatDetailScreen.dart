import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String image;
  final String navigationSource;
  final String userId;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.image,
    required this.navigationSource,
    required this.userId,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  String? _filePath;
  late String _profileImageUrl;
  String? _collectionName;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _requestMicrophonePermission();
    _profileImageUrl = widget.image;
    _initializeCollectionName();
    _loadProfileImage();
    _initializeSpeech();
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _initializeCollectionName() async {
    setState(() {
      if (widget.navigationSource == 'productsScreen') {
        _collectionName = 'ChatAsSeller';
      } else if (widget.navigationSource == 'VeterinaryScreen') {
        _collectionName = 'ChatAsVeterinary';
      } else {
        _collectionName = 'ChatAsBuyer';
      }
    });
  }

  Future<void> _loadProfileImage() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.userId)
        .get();
    if (userDoc.exists &&
        userDoc.data()!.containsKey('profileImage') &&
        userDoc['profileImage'] != null &&
        userDoc['profileImage'].isNotEmpty) {
      setState(() {
        _profileImageUrl = userDoc['profileImage'];
      });
    } else {
      setState(() {
        _profileImageUrl = 'asset/image/default_profile.png';
      });
    }
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (!mounted) return;

    setState(() => _isListening = available);
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (val) => setState(() {
            _lastWords = val.recognizedWords;
            _messageController.text = _lastWords;
          }),
        );
      }
    }
  }

  void _stopListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  Future<void> _sendMessage(String message, {String? imageUrl}) async {
    setState(() {
      _isSending = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final messageData = {
      'text': message,
      'senderId': currentUser.uid,
      'receiverId': widget.userId,
      'timestamp': timestamp,
      'imageUrl': imageUrl ?? ''
    };

    String senderCollectionName;
    String receiverCollectionName = 'ChatAsBuyer';

    if (widget.navigationSource == 'productsScreen') {
      senderCollectionName = 'ChatAsSeller';
    } else if (widget.navigationSource == 'VeterinaryScreen') {
      senderCollectionName = 'ChatAsVeterinary';
    } else {
      senderCollectionName = 'ChatAsBuyer';
      receiverCollectionName = await _getReceiverCollectionName(widget.userId);
    }

    await _saveMessageToCollection(
        currentUser.uid, widget.userId, senderCollectionName, messageData);
    await _saveMessageToCollection(
        widget.userId, currentUser.uid, receiverCollectionName, messageData);

    _messageController.clear();
    _clearSelectedImage();
    setState(() {
      _isSending = false;
    });
  }

  Future<String> _getReceiverCollectionName(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();
    if (userDoc.exists && userDoc.data()!.containsKey('position')) {
      final position = userDoc['position'];
      if (position == 'Buyer-Seller') {
        return 'ChatAsSeller';
      } else if (position == 'Buyer-Veterinary') {
        return 'ChatAsVeterinary';
      }
    }
    return 'ChatAsBuyer';
  }

  Future<void> _saveMessageToCollection(
    String fromId,
    String toId,
    String collectionName,
    Map<String, dynamic> messageData,
  ) async {
    final chatDoc = FirebaseFirestore.instance
        .collection('user')
        .doc(fromId)
        .collection(collectionName)
        .doc(toId);

    final chatSnapshot = await chatDoc.get();

    if (chatSnapshot.exists) {
      chatDoc.update({
        'messages': FieldValue.arrayUnion([messageData])
      });
    } else {
      chatDoc.set({
        'messages': [messageData]
      });
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'heic'],
    );

    if (result != null) {
      String? filePath = result.files.single.path;

      setState(() {
        _filePath = filePath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected file: ${filePath?.split('/').last}'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File selection canceled.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<String?> _uploadImageToCloudinary(String filePath) async {
    try {
      const cloudName = 'db3cpgdwm';
      const uploadPreset = 'message_preset';
      const apiKey = '545187993373729';
      const apiSecret = 'gdgWv-rubTrQTMn6KG0T7-Q5Cfw';

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signatureString =
          'folder=messages&timestamp=$timestamp&upload_preset=$uploadPreset$apiSecret';
      final signature = sha1.convert(utf8.encode(signatureString)).toString();

      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      var request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp
        ..fields['signature'] = signature
        ..fields['folder'] = 'messages'
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();
      final responseData = await response.stream.toBytes();
      final jsonResponse = json.decode(String.fromCharCodes(responseData));

      if (response.statusCode == 200) {
        print("Upload successful: $jsonResponse");
        return jsonResponse['secure_url'];
      } else {
        print("Error uploading image: ${response.statusCode}");
        print("Response Data: ${String.fromCharCodes(responseData)}");
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _filePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: _profileImageUrl.startsWith('asset/')
                  ? AssetImage(_profileImageUrl)
                  : NetworkImage(_profileImageUrl) as ImageProvider<Object>,
              radius: 20,
              onBackgroundImageError: (_, __) {
                setState(() {
                  _profileImageUrl = 'asset/image/default_profile.png';
                });
              },
            ),
            const SizedBox(width: 10),
            Text(
              widget.name,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: _collectionName == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('user')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection(_collectionName!)
                        .doc(widget.userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData ||
                          snapshot.data == null ||
                          !snapshot.data!.exists) {
                        return const Center(child: Text('No messages yet.'));
                      }

                      final chatData =
                          snapshot.data?.data() as Map<String, dynamic>?;
                      var messages = chatData?['messages'] ?? [];

                      messages.sort((a, b) => int.parse(a['timestamp'])
                          .compareTo(int.parse(b['timestamp'])));

                      Map<String, List<Map<String, dynamic>>> groupedMessages =
                          {};
                      for (var message in messages) {
                        String date = DateFormat('yyyy-MM-dd').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                int.parse(message['timestamp'])));
                        if (groupedMessages[date] == null) {
                          groupedMessages[date] = [];
                        }
                        groupedMessages[date]!.add(message);
                      }

                      List<Widget> messageWidgets = [];
                      groupedMessages.forEach((date, dateMessages) {
                        messageWidgets.add(
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              date,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                        dateMessages.forEach((message) {
                          final isMe = message['senderId'] ==
                              FirebaseAuth.instance.currentUser?.uid;
                          final displayMessage = message['text'];
                          final formattedTime = DateFormat('hh:mm a').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  int.parse(message['timestamp'])));
                          messageWidgets.add(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 14),
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Material(
                                    borderRadius: BorderRadius.circular(10),
                                    elevation: 5,
                                    color: isMe
                                        ? Colors.blue[200]
                                        : Colors.grey[300],
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 15),
                                      child: Column(
                                        crossAxisAlignment: isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          if (message['imageUrl'] != null &&
                                              message['imageUrl'].isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 10.0),
                                              child: Image.network(
                                                message['imageUrl'],
                                                height: 150,
                                                width: 150,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          Text(
                                            displayMessage,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isMe
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            formattedTime,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isMe
                                                  ? Colors.white60
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      });

                      return ListView(
                        children: messageWidgets,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _pickFile(context),
                        icon: Icon(
                          Icons.attach_file,
                          color: isDark ? Colors.grey[400] : Colors.grey[800],
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                        ),
                      ),
                      _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            )
                          : IconButton(
                              onPressed: () async {
                                final message = _messageController.text.trim();
                                String? imageUrl;
                                if (_filePath != null) {
                                  imageUrl = await _uploadImageToCloudinary(
                                      _filePath!);
                                }
                                if (message.isNotEmpty || imageUrl != null) {
                                  await _sendMessage(message,
                                      imageUrl: imageUrl);
                                }
                              },
                              icon: Icon(
                                Icons.send,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ],
                  ),
                ),
                if (_filePath != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        Image.file(
                          File(_filePath!),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _clearSelectedImage,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
