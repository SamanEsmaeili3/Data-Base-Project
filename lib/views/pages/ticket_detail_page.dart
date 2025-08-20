// lib/views/pages/ticket_details_page.dart

import 'package:flutter/material.dart';
import 'package:hand_made/provider/booking_provider.dart';
import 'package:hand_made/provider/ticket_provider.dart';
import 'package:provider/provider.dart';

class TicketDetailsPage extends StatefulWidget {
  final int ticketId;
  const TicketDetailsPage({super.key, required this.ticketId});

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(
        context,
        listen: false,
      ).fetchTicketDetails(widget.ticketId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جزئیات بلیط')),
      body: Consumer<TicketProvider>(
        builder: (context, ticketProvider, child) {
          if (ticketProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ticketProvider.errorMessage != null) {
            return Center(
              child: Text(
                ticketProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (ticketProvider.ticketDetails == null) {
            return const Center(child: Text('اطلاعات بلیط یافت نشد.'));
          }

          final ticket = ticketProvider.ticketDetails!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ticket.origin} به ${ticket.destination}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const Divider(height: 20),
                            _buildDetailRow(
                              'شرکت مسافربری:',
                              ticket.companyName,
                            ),
                            _buildDetailRow(
                              'تاریخ حرکت:',
                              ticket.departureDate,
                            ),
                            _buildDetailRow('ساعت حرکت:', ticket.departureTime),
                            _buildDetailRow('تاریخ رسیدن:', ticket.arrivalDate),
                            _buildDetailRow('ساعت رسیدن:', ticket.arrivalTime),
                            _buildDetailRow(
                              'ظرفیت باقیمانده:',
                              '${ticket.remainingCapacity} نفر',
                            ),

                            // *** UPDATED FEATURES SECTION ***
                            if (ticket.features != null)
                              _buildFeaturesSection(context, ticket.features!),

                            const Divider(height: 20),
                            Text(
                              '${ticket.price} تومان',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: Colors.green.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // --- Reservation Button ---
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Consumer<BookingProvider>(
                    builder: (context, bookingProvider, child) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed:
                            bookingProvider.isLoading
                                ? null
                                : () async {
                                  final success = await bookingProvider
                                      .reserveTicket(widget.ticketId);
                                  if (mounted) {
                                    final message =
                                        bookingProvider.successMessage ??
                                        bookingProvider.errorMessage ??
                                        'یک خطا رخ داد.';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                        backgroundColor:
                                            success ? Colors.green : Colors.red,
                                      ),
                                    );
                                    if (success) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                        child:
                            bookingProvider.isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text('رزرو بلیط'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  // Updated widget to build the features section dynamically
  Widget _buildFeaturesSection(
    BuildContext context,
    Map<String, dynamic> features,
  ) {
    // This expanded map now includes keys for all vehicle types.
    const keyTranslations = {
      // General
      'CompanyName': 'نام شرکت',
      'Features': 'سایر ویژگی ها',
      'Feature': 'سایر ویژگی ها',

      // Airplane Features
      'SeatClass': 'کلاس پرواز',
      'FlightClass': 'کلاس پرواز',
      'FlightNumber': 'شماره پرواز',
      'NumberOfStops': 'تعداد توقف‌ها',
      'OriginAirPort': 'فرودگاه مبدا',
      'DestinationAirPort': 'فرودگاه مقصد',

      // Bus Features
      'BusType': 'نوع اتوبوس',
      'ChairInRow': 'تعداد صندلی در ردیف',

      // Train Features
      'NumberOfStars': 'تعداد ستاره‌ها',
      'ClosedCompartment': 'کوپه دربست',
    };

    final featureWidgets = <Widget>[];

    for (final entry in features.entries) {
      // Skip redundant keys or features with no value
      if (entry.key == 'TicketID' || entry.key == 'Type' || entry.value == null)
        continue;

      final displayName = keyTranslations[entry.key] ?? entry.key;
      String displayValue;

      if (entry.value is bool) {
        displayValue = entry.value ? 'دارد' : 'ندارد';
      } else {
        displayValue = entry.value.toString();
      }

      featureWidgets.add(_buildDetailRow(displayName, displayValue));
    }

    if (featureWidgets.isEmpty) {
      return const SizedBox.shrink(); // Return an empty widget if no features
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20),
        Text(
          'امکانات و ویژگی‌ها:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...featureWidgets,
      ],
    );
  }
}
