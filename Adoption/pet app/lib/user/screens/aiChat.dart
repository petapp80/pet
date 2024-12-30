import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AIWebView extends StatefulWidget {
  @override
  _AIWebViewState createState() => _AIWebViewState();
}

class _AIWebViewState extends State<AIWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  // Your custom HTML, CSS, and JavaScript
  final String _htmlContent = """
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Chatbot</title>
            <style>
              body {
                margin: 0;
                padding: 0;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                background-color: #f0f0f0;
              }
              iframe {
                width: 100%;
                max-width: 400px;
                height: 90vh;
                border: none;
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
                border-radius: 10px;
              }
            </style>
          </head>
          <body>
            <iframe
              id="chatbot-iframe"
              src="https://www.chatbase.co/chatbot-iframe/IJc3_Fid4H7F4L2Mf35T3"
              allow="camera; microphone; autoplay; encrypted-media"
            ></iframe>
            <script>
              const iframe = document.getElementById('chatbot-iframe');
              // Listen for postMessage from the iframe (if any)
              window.addEventListener('message', (event) => {
                if (event.origin === 'https://www.chatbase.co') {
                  // Handle data received from iframe here (e.g., user input)
                  console.log(event.data); // For example, log the data
                }
              });
            </script>
          </body>
          </html>
      """;

  @override
  void initState() {
    super.initState();
    // Initialize WebView
    WebViewController webController = WebViewController();
    _controller = webController;

    // Enable JavaScript for the WebView
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    // Load the HTML content
    _controller.loadRequest(Uri.dataFromString(
      _htmlContent,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    ));

    // Add listener to track when the page finishes loading
    _controller.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (url) {
        setState(() {
          _isLoading = false; // Hide loading spinner after page loads
        });
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pet App AI'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          WebViewWidget(
            controller: _controller,
          ),
          if (_isLoading) // Show loading spinner while page is loading
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
