import 'package:flutter/material.dart';
import 'package:hand_made/provider/booking_provider.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  @override
  void initState() {
    super.initState();
    // Fetch bookings as soon as the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchUserBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading && bookingProvider.bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookingProvider.errorMessage != null &&
              bookingProvider.bookings.isEmpty) {
            return Center(child: Text(bookingProvider.errorMessage!));
          }

          if (bookingProvider.bookings.isEmpty) {
            return const Center(
              child: Text('هیچ رزروی برای نمایش وجود ندارد.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => bookingProvider.fetchUserBookings(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: bookingProvider.bookings.length,
              itemBuilder: (context, index) {
                final booking = bookingProvider.bookings[index];
                return _buildBookingCard(context, booking);
              },
            ),
          );
        },
      ),
    );
  }

  // --- Dialog for Payment ---
  void _showPaymentDialog(BuildContext context, int reservationId) {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('انتخاب روش پرداخت'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _paymentOption(
                dialogContext,
                'کارت بانکی',
                'Card',
                reservationId,
                bookingProvider,
              ),
              _paymentOption(
                dialogContext,
                'کیف پول',
                'Wallet',
                reservationId,
                bookingProvider,
              ),
              _paymentOption(
                dialogContext,
                'ارز دیجیتال',
                'Crypto',
                reservationId,
                bookingProvider,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('انصراف'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _paymentOption(
    BuildContext dialogContext,
    String title,
    String method,
    int reservationId,
    BookingProvider provider,
  ) {
    return ListTile(
      title: Text(title),
      onTap: () async {
        Navigator.of(dialogContext).pop();
        final success = await provider.payForReservation(reservationId, method);
        if (mounted && !success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'خطا در پرداخت'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  // --- Dialog for Cancellation ---
  void _showCancelConfirmationDialog(
    BuildContext context,
    int reservationId,
    int ticketId,
  ) async {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    try {
      final penaltyInfo = await bookingProvider.checkCancellationPenalty(
        ticketId,
      );
      final refundAmount = penaltyInfo['refund_amount'];
      final penaltyAmount = penaltyInfo['penalty_amount'];

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('تایید کنسلی بلیط'),
            content: Text(
              'آیا از کنسل کردن این بلیط اطمینان دارید؟\n\nمبلغ جریمه: $penaltyAmount تومان\nمبلغ قابل استرداد: $refundAmount تومان',
            ),
            actions: [
              TextButton(
                child: const Text('انصراف'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: const Text(
                  'تایید و کنسل کردن',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final success = await bookingProvider.cancelReservation(
                    reservationId,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          bookingProvider.successMessage ??
                              bookingProvider.errorMessage ??
                              'خطا',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در دریافت اطلاعات جریمه: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Main Booking Card Widget ---
  Widget _buildBookingCard(
    BuildContext context,
    UserBookingDetailsResponse booking,
  ) {
    final bool isReserved = booking.reservationStatus == 'Reserved';
    final bool isPaid = booking.reservationStatus == 'Paid';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${booking.ticketDetails.origin} به ${booking.ticketDetails.destination}',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(booking.reservationStatus),
              ],
            ),
            const Divider(height: 20),
            Text('شرکت: ${booking.ticketDetails.companyName}'),
            Text('تاریخ حرکت: ${booking.ticketDetails.departureDateTime}'),
            Text('قیمت: ${booking.ticketDetails.price.toInt()} تومان'),

            // --- Conditional Buttons ---
            if (isReserved || isPaid) const SizedBox(height: 16),
            if (isReserved)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
                onPressed:
                    () => _showPaymentDialog(context, booking.reservationId),
                child: const Text('پرداخت'),
              ),
            if (isPaid)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 40),
                ),
                onPressed:
                    () => _showCancelConfirmationDialog(
                      context,
                      booking.reservationId,
                      booking.ticketId,
                    ),
                child: const Text('کنسل کردن بلیط'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'Reserved':
        color = Colors.orange;
        text = 'رزرو شده';
        break;
      case 'Paid':
        color = Colors.green;
        text = 'پرداخت شده';
        break;
      case 'Cancelled':
        color = Colors.red;
        text = 'کنسل شده';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
