import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReceivePaymentPage extends StatefulWidget {
  final String ipAddress;
  final String username;

  const ReceivePaymentPage({
    super.key,
    required this.ipAddress,
    required this.username,
  });

  @override
  State<ReceivePaymentPage> createState() => _ReceivePaymentPageState();
}

class _ReceivePaymentPageState extends State<ReceivePaymentPage> {
  late Future<Map<String, dynamic>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = fetchReceivedPayments();
  }

  Future<Map<String, dynamic>> fetchReceivedPayments() async {
    final url = Uri.parse("http://${widget.ipAddress}:5000/untransact");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'payee': widget.username}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data['processed'] != null) {
        return data['processed'];
      }
    }

    return {"total": 0, "records": []};
  }

  String formatDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year.toString().substring(2)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B66E8),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 18, right: 18),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Receive Payment",
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // BODY
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _paymentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final payments = snapshot.data?['records'] ?? [];
                  final total = snapshot.data?['total'] ?? 0;

                  // NO RECORDS
                  if (payments.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),
                        Container(
                          padding: const EdgeInsets.all(34),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 19,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.sentiment_dissatisfied,
                                  color: Colors.grey, size: 54),
                              SizedBox(height: 16),
                              Text(
                                "Sorry, No records Found",
                                style:
                                    TextStyle(fontSize: 18, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          "Server: ${widget.ipAddress}",
                          style:
                              const TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ],
                    );
                  }

                  // RECORD LIST
                  return ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 17,
                              offset: const Offset(0, 6),
                            )
                          ],
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Received",
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              "₹$total",
                              style: const TextStyle(
                                fontSize: 33,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "from ${payments.length} payers",
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        "Server: ${widget.ipAddress}",
                        style: const TextStyle(fontSize: 15, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // HEADER ROW
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 14),
                        child: const Row(
                          children: [
                            Expanded(
                                child: Text("Date",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15))),
                            Expanded(
                                child: Text("From",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15))),
                            Expanded(
                                child: Text("Amount",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15))),
                          ],
                        ),
                      ),

                      // LIST ITEMS
                      ...payments.map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatDate(item['transaction_time']),
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item['from'],
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "₹${item['amount']}",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
