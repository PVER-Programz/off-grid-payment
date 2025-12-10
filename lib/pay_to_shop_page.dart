import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PayToShopPage extends StatefulWidget {
  final String ipAddress;
  final String senderUsername;

  const PayToShopPage({
    super.key,
    required this.ipAddress,
    required this.senderUsername,
  });

  @override
  State<PayToShopPage> createState() => _PayToShopPageState();
}

class _PayToShopPageState extends State<PayToShopPage> {
  final TextEditingController amountController = TextEditingController();

  String merchantName = "";
  bool fetchingMerchant = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMerchant();
  }

  Future<void> _fetchMerchant() async {
    final url = Uri.parse("http://${widget.ipAddress}:5000/merchantname");

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      merchantName = data["merchant"] ?? "Unknown Shop";
    } catch (e) {
      merchantName = "Unknown Shop";
    }

    setState(() => fetchingMerchant = false);
  }

  Future<void> _sendPayment() async {
    final amount = double.tryParse(amountController.text);
    if (amount == null) {
      _error("Enter valid amount");
      return;
    }

    final url = Uri.parse("http://${widget.ipAddress}:5000/pay");

    final data = {
      "username": widget.senderUsername, // << YOUR NAME
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
        _success("Payment successful!");

        Navigator.pop(context, amount); // << SEND AMOUNT BACK TO PORTFOLIO PAGE
      } else {
        _error("Payment failed: ${response.body}");
      }
    } catch (e) {
      _error("Error: $e");
    }

    setState(() => isLoading = false);
  }

  void _success(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // Header
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
                      "Pay to Shop",
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
                      fetchingMerchant
                          ? const CircularProgressIndicator()
                          : Column(
                              children: [
                                const Icon(Icons.storefront, size: 50),
                                Text(merchantName,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                Text(widget.ipAddress,
                                    style:
                                        const TextStyle(color: Colors.grey)),
                              ],
                            ),

                      const SizedBox(height: 40),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Enter Amount"),
                      ),

                      const SizedBox(height: 10),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _sendPayment,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Pay"),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
