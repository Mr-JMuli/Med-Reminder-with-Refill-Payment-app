import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MedReminderApp());
}

class MedReminderApp extends StatelessWidget {
  const MedReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Med Reminder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MedListScreen(),
    );
  }
}

class MedListScreen extends StatefulWidget {
  const MedListScreen({super.key});

  @override
  _MedListScreenState createState() => _MedListScreenState();
}

class _MedListScreenState extends State<MedListScreen> {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final List<Map<String, String>> medications = [
    {'name': 'Ibuprofen', 'schedule': 'Daily at 8 AM'},
    {'name': 'Paracetamol', 'schedule': 'Every 6 hours'},
  ];
  bool reminderEnabled = false;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  void initializeNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await notificationsPlugin.initialize(initSettings);
  }

  void toggleReminder() async {
    setState(() {
      reminderEnabled = !reminderEnabled;
    });
    if (reminderEnabled) {
      await notificationsPlugin.show(
        0,
        'Med Reminder',
        'Time to take your medication!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'med_channel',
            'Medication Reminders',
            importance: Importance.high,
          ),
        ),
      );
    } else {
      await notificationsPlugin.cancelAll();
    }
  }

  Future<void> initiatePayment() async {
    const url = 'https://api.flutterwave.com/v3/payments';
    const apiKey = 'FLWSECK_TEST-YOUR_TEST_KEY'; // Replace with your Flutterwave sandbox key
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tx_ref': 'ref-${DateTime.now().millisecondsSinceEpoch}',
        'amount': 10,
        'currency': 'USD',
        'redirect_url': 'https://your-redirect-url.com/success',
        'customer': {'email': 'customer@example.com'},
        'customizations': {
          'title': 'Pharmacy Refill Payment',
          'description': 'Payment for medication refill',
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // In a real app, open data['data']['link'] in a WebView
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PaymentSuccessScreen(),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment initiation failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Med Reminder')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable Reminders'),
            value: reminderEnabled,
            onChanged: (value) => toggleReminder(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final med = medications[index];
                return ListTile(
                  title: Text(med['name']!),
                  subtitle: Text(med['schedule']!),
                  trailing: ElevatedButton(
                    onPressed: initiatePayment,
                    child: const Text('Refill Now'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Success')),
      body: const Center(
        child: Text(
          'Refill Payment Successful!\nYour medication will be prepared.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}