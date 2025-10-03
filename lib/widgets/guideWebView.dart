
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';


class ManualWebView extends StatefulWidget {
  final String url;
  const ManualWebView({super.key, required this.url});

  @override
  State<ManualWebView> createState() => _ManualWebViewState();
}

class _ManualWebViewState extends State<ManualWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('מדריך למשתמש')),
      body: WebViewWidget(controller: _controller),
    );
  }
}