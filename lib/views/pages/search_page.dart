import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'جستوجو بلیط',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(border: OutlineInputBorder()),
            onSubmitted: (value) {
              // Handle search action
              print('Searching for: $value');
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50), // Full width button
            ),
            onPressed: () {},
            child: Text("جستوجو"),
          ),
        ],
      ),
    );
  }
}
