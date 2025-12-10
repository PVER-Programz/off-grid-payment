import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'pay_to_friend_page.dart';
import 'scan.dart';
import 'profile.dart';
import 'pay_to_shop_page.dart';
import 'recive_page.dart';
import 'add_funds.dart';

final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({Key? key}) : super(key: key);

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  String? connectedIp;
  String username = '';
  double balance = 0.0;

  final List<Map<String, dynamic>> transactions = [];

  final currencyFormatter = NumberFormat.currency(locale: "en_IN", symbol: "₹");

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final storedUsername = await secureStorage.read(key: 'user_username');
    if (storedUsername != null && storedUsername.isNotEmpty) {
      setState(() => username = storedUsername);
    }
  }

  bool _validateIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    for (var p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }

  // ------------------------------------------------------------
  // ADD FUNDS
  // ------------------------------------------------------------
  Future<void> _navigateToAddFunds() async {
    final added = await Navigator.push<double>(
      context,
      MaterialPageRoute(builder: (context) => const AddFundsPage()),
    );

    if (added != null && added > 0) {
      setState(() {
        balance += added;
        transactions.insert(0, {
          'name': 'Funds Added',
          'method': 'Wallet Top-up',
          'amount': added,
          'type': 'receive',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("₹${added.toStringAsFixed(2)} added to wallet!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // SEND BOTTOM SHEET
  // ------------------------------------------------------------
  void _showSendOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choose Payment Type",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Pay To Friend
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text("Pay to Friend", style: TextStyle(fontSize: 18)),
                onTap: () async {
                  Navigator.pop(context);

                  final sentAmount = await Navigator.push<double>(
                    context,
                    MaterialPageRoute(builder: (_) => PayToFriendPage(ipAddress: connectedIp!,senderUsername: username,)),
                  );

                  if (sentAmount != null && sentAmount > 0) {
                    setState(() {
                      balance -= sentAmount;
                      transactions.insert(0, {
                        'name': 'Sent to Friend',
                        'method': 'Hotspot Transfer',
                        'amount': sentAmount,
                        'type': 'send',
                      });
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("₹$sentAmount sent successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),

              const Divider(),

              // Pay to Shop
              ListTile(
                leading: const Icon(Icons.storefront, color: Colors.green),
                title: const Text("Pay to Shop", style: TextStyle(fontSize: 18)),
                onTap: () async {
                  Navigator.pop(context);

                  final sentAmount = await Navigator.push<double>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PayToShopPage(
                        ipAddress: connectedIp!,
                        senderUsername: username,
                      ),
                    ),
                  );

                  if (sentAmount != null && sentAmount > 0) {
                    setState(() {
                      balance -= sentAmount;
                      transactions.insert(0, {
                        'name': 'Shop Payment',
                        'method': 'Hotspot Transfer',
                        'amount': sentAmount,
                        'type': 'send',
                      });
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("₹$sentAmount paid to shop!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // UI START
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isConnected = connectedIp != null;

    return Scaffold(
      backgroundColor: const Color(0xFF6B66E8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- Top Bar ----------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          // QR SCAN
                          GestureDetector(
                            onTap: () async {
                              final ip = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const QrScanPage()),
                              );

                              if (ip != null && ip is String && _validateIp(ip)) {
                                setState(() => connectedIp = ip);
                              }
                            },
                            child: _circleButton(Icons.qr_code_scanner,
                                isConnected ? Colors.green : Colors.red),
                          ),
                          const SizedBox(width: 9),

                          // EDIT IP
                          GestureDetector(
                            onTap: _showEditIpDialog,
                            child: _circleButton(Icons.edit_rounded,
                                isConnected ? Colors.green : Colors.red),
                          ),

                          const SizedBox(width: 12),

                          // IP STATUS
                          Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 12, color: isConnected ? Colors.green : Colors.red),
                              const SizedBox(width: 7),
                              Text(
                                isConnected ? connectedIp! : "Scan QR",
                                style: TextStyle(
                                  color: isConnected ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 12),

                          // ⭐ PROFILE ICON ADDED HERE
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfilePage()),
                              );
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFEDEAFF),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.person,
                                  color: Color(0xFF7B67E9), size: 26),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 19),

                  // ---------------- Username ----------------
                  Text(
                    username.isEmpty ? "My Portfolio" : "$username's Portfolio",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 30, color: Color(0xFF202233)),
                  ),

                  const SizedBox(height: 19),

                  // ---------------- Balance Card ----------------
                  _balanceCard(),

                  const SizedBox(height: 28),

                  _sendReceiveButtons(),

                  const SizedBox(height: 28),

                  _transactionList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------- SMALL HELPERS -------------------------------------

  Widget _circleButton(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withOpacity(.09),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(9),
      child: Icon(icon, color: color, size: 26),
    );
  }

  // ⭐ BALANCE CARD WITH + BUTTON ⭐
  Widget _balanceCard() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(30, 24, 58, 35),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 10),
              Text(
                currencyFormatter.format(balance),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 38),
              ),
              const SizedBox(height: 11),
              const Text("**** 8149",
                  style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 6)),
            ],
          ),
        ),

        // ⭐ Floating + Button for Add Funds
        Positioned(
          right: 18,
          bottom: 13,
          child: GestureDetector(
            onTap: _navigateToAddFunds,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF7C5DF9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- SEND / RECEIVE BUTTONS ----------------------

  Widget _sendReceiveButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionBox(
            color: Colors.green,
            icon: Icons.arrow_upward_rounded,
            label: "Send",
            onTap: () {
              if (connectedIp != null) {
                _showSendOptions();
              } else {
                _showError("Please connect first!");
              }
            },
          ),
        ),
        Expanded(
          child: _actionBox(
            color: Colors.red,
            icon: Icons.arrow_downward_rounded,
            label: "Receive",
            onTap: () async {
              if (connectedIp != null && username.isNotEmpty) {
                final receivedAmount = await Navigator.push<double>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReceivePaymentPage(ipAddress: connectedIp!, username: username),
                  ),
                );

                if (receivedAmount != null && receivedAmount > 0) {
                  setState(() {
                    balance += receivedAmount;
                    transactions.insert(0, {
                      'name': 'Payment Received',
                      'method': 'Hotspot',
                      'amount': receivedAmount,
                      'type': 'receive'
                    });
                  });

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("₹$receivedAmount received!"),
                    backgroundColor: Colors.green,
                  ));
                }
              } else {
                _showError("Connect first!");
              }
            },
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Colors.red),
    );
  }

  Widget _actionBox({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 9),
      height: 87,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 13)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration:
                  BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.all(13),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TRANSACTION HISTORY
  // ------------------------------------------------------------
  Widget _transactionList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            username.isEmpty ? "Transaction History" : "$username's Transactions",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21),
          ),
          const SizedBox(height: 3),
          const Text("A list of historical transactions",
              style: TextStyle(color: Color(0xFF8D8EA2), fontSize: 13)),
          const SizedBox(height: 14),

          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _txnItem(txn['name'], txn['method'], txn['amount'], txn['type']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _txnItem(String name, String method, double amount, String type) {
    final bool isSend = type == 'send';
    final Color color = isSend ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            decoration:
                BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(13)),
            padding: const EdgeInsets.all(10),
            child: Icon(isSend ? Icons.arrow_upward : Icons.arrow_downward,
                color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 1),
                Text('Paid with: $method',
                    style: const TextStyle(fontSize: 13, color: Color(0xFFB2B5BF))),
              ],
            ),
          ),
          Text(
            currencyFormatter.format(amount),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // IP EDIT DIALOG
  // ------------------------------------------------------------

  void _showEditIpDialog() {
    final a = TextEditingController();
    final b = TextEditingController();
    final c = TextEditingController();
    final d = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter IP Address"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ipBox(a),
            const Text('.'),
            _ipBox(b),
            const Text('.'),
            _ipBox(c),
            const Text('.'),
            _ipBox(d),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final ip = "${a.text}.${b.text}.${c.text}.${d.text}";

              if (_validateIp(ip)) {
                setState(() => connectedIp = ip);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Invalid IP"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _ipBox(TextEditingController c) {
    return SizedBox(
      width: 35,
      child: TextField(
        controller: c,
        maxLength: 3,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(counterText: ''),
      ),
    );
  }
}
