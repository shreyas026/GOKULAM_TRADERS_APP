import 'dart:io';
import 'package:flutter/material.dart' hide Image;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order_model.dart';

class InvoiceService {
  static Future<pw.Document> generateInvoicePdf(OrderDetailModel order) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('GOKULAM TRADERS', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1B5E20))),
                    pw.Text('Smart Hardware, Electrical & Plumbing Store', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    pw.SizedBox(height: 4),
                    pw.Text('123 Main Road, Bangalore - 560001', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('GST: 29ABCDE1234F1Z5 | Phone: +91-9876543210', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColor.fromInt(0xFF1B5E20)),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1B5E20))),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Invoice #: ${order.orderId}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Date: ${order.createdAt.substring(0, 10)}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          pw.Divider(thickness: 1.5, color: PdfColor.fromInt(0xFF1B5E20)),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bill To:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('Customer', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Type: ${order.deliveryType.replaceAll('_', ' ').toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Payment: ${order.paymentMethod.replaceAll('_', ' ').toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Status: ${order.paymentStatus.toUpperCase()}', style: pw.TextStyle(fontSize: 10, color: order.paymentStatus == 'completed' ? PdfColors.green : PdfColors.orange)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Product', 'Qty', 'Price', 'GST%', 'GST Amt', 'Total'],
            data: List.generate(order.items.length, (i) {
              final item = order.items[i];
              return [
                '${i + 1}',
                item.productName,
                '${item.quantity}',
                '₹${item.price.toStringAsFixed(0)}',
                '${item.gstPercent.toStringAsFixed(0)}%',
                '₹${item.gstAmount.toStringAsFixed(0)}',
                '₹${item.total.toStringAsFixed(0)}',
              ];
            }),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF1B5E20)),
            cellStyle: const pw.TextStyle(fontSize: 9),
            border: pw.TableBorder.all(color: PdfColors.grey),
            headerAlignment: pw.Alignment.center,
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.center,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
            },
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Subtotal:          ₹${order.subtotal.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text('GST Total:         ₹${order.gstAmount.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 11)),
                  if (order.deliveryCharge > 0) pw.Text('Delivery:            ₹${order.deliveryCharge.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 11)),
                  if (order.discountAmount > 0) pw.Text('Discount:           -₹${order.discountAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 11, color: PdfColors.green)),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColor.fromInt(0xFF1B5E20), width: 2),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'Grand Total: ₹${order.totalAmount.toStringAsFixed(0)}',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1B5E20)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('GST: CGST = ${(order.gstAmount / 2).toStringAsFixed(2)} | SGST = ${(order.gstAmount / 2).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1B5E20))),
        ],
      ),
    );
    return pdf;
  }

  static Future<void> printInvoice(OrderDetailModel order) async {
    final pdf = await generateInvoicePdf(order);
    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'Invoice_${order.orderId}',
    );
  }

  static Future<void> shareInvoice(OrderDetailModel order) async {
    final pdf = await generateInvoicePdf(order);
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Invoice_${order.orderId}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Invoice - Gokulam Traders (${order.orderId})',
      text: 'Gokulam Traders - Invoice #${order.orderId}\nAmount: ₹${order.totalAmount.toStringAsFixed(0)}',
    );
  }

  static Future<void> sendViaWhatsApp(OrderDetailModel order, String phone) async {
    final phoneClean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final invoiceText = Uri.encodeComponent(
      '*GOKULAM TRADERS*\n'
      'Invoice #${order.orderId}\n'
      'Amount: ₹${order.totalAmount.toStringAsFixed(0)}\n'
      'Items: ${order.items.length}\n'
      'Payment: ${order.paymentMethod.replaceAll('_', ' ').toUpperCase()}\n'
      '---\n'
      '${order.items.map((i) => '${i.productName} x${i.quantity} = ₹${i.total.toStringAsFixed(0)}').join('\n')}\n'
      '---\n'
      'Subtotal: ₹${order.subtotal.toStringAsFixed(0)}\n'
      'GST: ₹${order.gstAmount.toStringAsFixed(0)}\n'
      'Grand Total: ₹${order.totalAmount.toStringAsFixed(0)}\n'
      '---\n'
      'Thank you for shopping with us!'
    );
    final url = 'https://wa.me/$phoneClean?text=$invoiceText';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  static Future<void> sendTextViaWhatsApp(String phone, String message) async {
    final phoneClean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/$phoneClean?text=$encoded';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}