import 'package:flutter/material.dart';

class OtpLoginPage extends StatefulWidget {
  const OtpLoginPage({super.key});

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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.number,
              controller: controller,
              decoration: InputDecoration(
                labelText: 'کد تایید دو مرحله ای',
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50), // Full width button
              ),
              onPressed: () {},
              child: Text("ورود"),
            ),
          ],
        ),
      ),
    );
  }
}
