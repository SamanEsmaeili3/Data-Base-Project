import 'package:flutter/material.dart';
import 'package:hand_made/provider/ticket_provider.dart';
import 'package:hand_made/views/pages/ticket_detail_page.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Local state for form fields
  CityModel? _selectedOrigin;
  CityModel? _selectedDestination;
  final _dateController = TextEditingController();
  String? _selectedvehicle;

  @override
  void initState() {
    super.initState();
    // Fetch cities when the page loads, without listening to updates here.
    // The Consumer widget will handle UI updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).fetchCities();
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in TicketProvider
    return Scaffold(
      body: Consumer<TicketProvider>(
        builder: (context, ticketProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // --- Search Form ---
                _buildSearchForm(context, ticketProvider),
                const SizedBox(height: 20),

                // --- Results Section ---
                _buildResultsSection(context, ticketProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchForm(BuildContext context, TicketProvider ticketProvider) {
    return Column(
      children: [
        if (ticketProvider.cities.isEmpty && ticketProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          DropdownButtonFormField<CityModel>(
            value: _selectedOrigin,
            hint: const Text('مبدا'),
            isExpanded: true,
            items:
                ticketProvider.cities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city.cityName),
                  );
                }).toList(),
            onChanged: (value) => setState(() => _selectedOrigin = value),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<CityModel>(
            value: _selectedDestination,
            hint: const Text('مقصد'),
            isExpanded: true,
            items:
                ticketProvider.cities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city.cityName),
                  );
                }).toList(),
            onChanged: (value) => setState(() => _selectedDestination = value),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
        const SizedBox(height: 10),
        DropdownButtonFormField(
          value: _selectedvehicle,
          hint: const Text("نوع وسیله نقلیه"),
          isExpanded: true,
          items: [
            DropdownMenuItem(child: Text("هواپیما"), value: "airplane"),
            DropdownMenuItem(child: Text("اتوبوس"), value: "bus"),
            DropdownMenuItem(child: Text("قطار"), value: "train"),
          ],
          onChanged: (value) {
            setState(() {
              _selectedvehicle = value;
              print("Selected Vehicle: $_selectedvehicle");
            });
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _dateController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'تاریخ (YYYY-MM-DD)',
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () {
            if (_selectedOrigin == null ||
                _selectedDestination == null ||
                _selectedvehicle == null ||
                _dateController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('لطفا تمام فیلدها را پر کنید')),
              );
              return;
            }
            ticketProvider.searchTickets(
              origin: _selectedOrigin!.cityName,
              destination: _selectedDestination!.cityName,
              date: _dateController.text,
              vehicleType: _selectedvehicle!, // You can add a dropdown for this
            );
          },
          child: const Text("جستجو"),
        ),
      ],
    );
  }

  Widget _buildResultsSection(
    BuildContext context,
    TicketProvider ticketProvider,
  ) {
    if (ticketProvider.isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (ticketProvider.errorMessage != null) {
      return Center(
        child: Text(
          ticketProvider.errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (ticketProvider.searchResults.isEmpty) {
      return const Center(
        child: Text("برای جستجوی بلیط، فرم بالا را پر کنید."),
      );
    }

    // If we have results, show them in a list
    return Expanded(
      child: ListView.builder(
        itemCount: ticketProvider.searchResults.length,
        itemBuilder: (context, index) {
          final ticket = ticketProvider.searchResults[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text("${ticket.origin} به ${ticket.destination}"),
              subtitle: Text(
                "${ticket.companyName} - ${ticket.departureDateTime}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${ticket.price.toInt()} تومان"),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'جزئیات',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  TicketDetailsPage(ticketId: ticket.ticketId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
