import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PayToFriendPage extends StatefulWidget {
  final String ipAddress;
  final String senderUsername; 
  const PayToFriendPage({
    Key? key,
    required this.ipAddress,
    required this.senderUsername,
  }) : super(key: key);

  @override
  State<PayToFriendPage> createState() => _PayToFriendPageState();
}

class _PayToFriendPageState extends State<PayToFriendPage> {
  final TextEditingController friendController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  bool isLoading = false;

  Future<void> _sendPayment() async {
    final String friend = friendController.text.trim();
    final amount = double.tryParse(amountController.text.trim());

    if (friend.isEmpty) {
      _error("Enter friend's username");
      return;
    }

    if (amount == null || amount <= 0) {
      _error("Enter valid amount");
      return;
    }

    final url = Uri.parse("http://${widget.ipAddress}:5000/transact");

    // ⭐ Updated JSON according to your backend format
    final data = {
      "from": widget.senderUsername,
      "to": friend,
      "amount": amount,
    };

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        _success("Sent ₹$amount to $friend");

        // Return amount back to PortfolioPage
        Navigator.pop(context, amount);
      } else {
        _error("Failed: ${response.body}");
      }
    } catch (e) {
      _error("Error: $e");
    }

    setState(() => isLoading = false);
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _success(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ UI NOT CHANGED AT ALL
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Pay to Friend",
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: friendController,
                        decoration: const InputDecoration(
                          labelText: "Friend Username",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.currency_rupee),
                          labelText: "Amount",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _sendPayment,
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Send", style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
