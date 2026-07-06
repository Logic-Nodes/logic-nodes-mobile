import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/home/domain/entities/home_dashboard.dart';

class TripPdfService {
  Future<void> shareTripPdf({
    required HomeTrip trip,
    required List<HomeDeliveryOrder> deliveryOrders,
  }) async {
    final doc = pw.Document();
    final generatedAt = DateTime.now().toLocal();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'OmniTrack — Trip Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Trip ID: ${trip.id}'),
          pw.Text('Status: ${trip.status}'),
          pw.SizedBox(height: 8),
          pw.Text('Origin: ${trip.originPointName ?? '—'}'),
          pw.Text('Address: ${trip.originPointAddress ?? '—'}'),
          pw.SizedBox(height: 8),
          pw.Text('Created: ${_format(trip.createdAt)}'),
          pw.Text('Started: ${_format(trip.startedAt)}'),
          pw.Text('Completed: ${_format(trip.completedAt)}'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Delivery orders (${deliveryOrders.length})',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if (deliveryOrders.isEmpty)
            pw.Text('No delivery orders recorded.')
          else
            pw.Table.fromTextArray(
              headers: const ['#', 'Client', 'Status', 'Address', 'Arrival'],
              data: deliveryOrders
                  .map(
                    (order) => [
                      '${order.sequenceOrder}',
                      order.clientEmail,
                      order.status,
                      order.address ?? '—',
                      _format(order.arrivalAt),
                    ],
                  )
                  .toList(growable: false),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Generated on ${_format(generatedAt)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => doc.save(),
      name: 'trip-${trip.id}.pdf',
    );
  }

  String _format(DateTime? value) {
    if (value == null) {
      return '—';
    }

    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
