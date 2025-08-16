import 'package:flutter/material.dart';
import 'package:hand_made/views/widget_tree.dart';

class OtpLoginPage extends StatefulWidget {
  const OtpLoginPage({super.key, required this.emailOrPhoneNumber});

  final String emailOrPhoneNumber;

  @override
  State<OtpLoginPage> createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends State<OtpLoginPage> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ورود دو مرحله ای',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              controller: controller,
              decoration: InputDecoration(
                labelText: 'کد تایید',
                border: OutlineInputBorder(),
              ),
              onEditingComplete: () {
                setState(() {});
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50), // Full width button
              ),
              onPressed: () {
                // TODO: Handle OTP verification
                // Remove all previous pages and go to WidgetTree
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => widgetTree()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text("ورود"),
            ),
          ],
        ),
      ),
    );
  }
}
