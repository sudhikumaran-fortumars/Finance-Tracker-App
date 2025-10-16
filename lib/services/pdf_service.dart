import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import '../models/user_scheme.dart';
import '../models/address.dart';
import '../utils/calculations.dart';

// PDF-specific currency formatter that uses "Rs." instead of ₹ symbol
String _formatCurrencyForPdf(double amount) {
  final formatter = NumberFormat('#,##0', 'en_IN');
  return 'Rs. ${formatter.format(amount)}';
}

class PdfService {
  static Future<void> generateReport({
    required List<User> users,
    required List<Transaction> transactions,
    required List<UserScheme> userSchemes,
    required String reportType,
    required String period,
    DateTimeRange? dateRange,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Add report content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(reportType, period),
              pw.SizedBox(height: 20),
              _buildSummarySection(users, transactions, userSchemes),
              pw.SizedBox(height: 20),
              _buildTransactionTable(transactions, users, dateRange),
              pw.SizedBox(height: 20),
              _buildUserDetailsTable(users, userSchemes),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ];
          },
        ),
      );

      // Save and open PDF
      if (kIsWeb) {
        await _saveAndOpenPdfWeb(pdf, reportType);
      } else {
        await _saveAndOpenPdf(pdf, reportType);
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
    }
  }

  static pw.Widget _buildHeader(String reportType, String period) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Finance Tracker Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Report Type: $reportType',
            style: pw.TextStyle(fontSize: 16, color: PdfColors.blue700),
          ),
          pw.Text(
            'Period: $period',
            style: pw.TextStyle(fontSize: 16, color: PdfColors.blue700),
          ),
          pw.Text(
            'Generated: ${DateTime.now().toString().split(' ')[0]}',
            style: pw.TextStyle(fontSize: 14, color: PdfColors.blue600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection(
    List<User> users,
    List<Transaction> transactions,
    List<UserScheme> userSchemes,
  ) {
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final totalUsers = users.length;
    final totalTransactions = transactions.length;
    final bonusEarned = transactions.fold(0.0, (sum, t) => sum + t.interest);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Users', totalUsers.toString()),
              _buildSummaryItem('Total Transactions', totalTransactions.toString()),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Amount', _formatCurrencyForPdf(totalAmount)),
              _buildSummaryItem(
                'Bonus Earned', 
                _formatCurrencyForPdf(bonusEarned)
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionTable(List<Transaction> transactions, List<User> users, DateTimeRange? dateRange) {
    // Filter transactions by date range if provided
    List<Transaction> filteredTransactions = transactions;
    if (dateRange != null) {
      filteredTransactions = transactions.where((t) {
        return t.date.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
               t.date.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent Transactions',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeader('Date'),
                _buildTableHeader('User'),
                _buildTableHeader('Amount'),
                _buildTableHeader('Mode'),
                _buildTableHeader('Bonus'),
              ],
            ),
            // Data rows
            ...filteredTransactions.take(20).map((transaction) {
              // Find user name from users list
              final user = users.firstWhere(
                (u) => u.id == transaction.userId,
                orElse: () => User(
                  id: 'unknown',
                  name: 'Unknown User',
                  mobileNumber: '0000000000',
                  serialNumber: '000',
                  status: UserStatus.active,
                  createdAt: DateTime.now(),
                  schemes: [],
                  permanentAddress: Address(
                    doorNumber: '0',
                    street: 'Unknown',
                    area: 'Unknown',
                    localAddress: 'Unknown',
                    city: 'Unknown',
                    district: 'Unknown',
                    state: 'Unknown',
                    pinCode: '000000',
                  ),
                ),
              );
              
              return pw.TableRow(
                children: [
                  _buildTableCell(Calculations.formatDate(transaction.date)),
                  _buildTableCell(user.name),
                  _buildTableCell(_formatCurrencyForPdf(transaction.amount)),
                  _buildTableCell(transaction.paymentMode.toString().split('.').last),
                  _buildTableCell(_formatCurrencyForPdf(transaction.interest)),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildUserDetailsTable(List<User> users, List<UserScheme> userSchemes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'User Details',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeader('Name'),
                _buildTableHeader('Mobile'),
                _buildTableHeader('Serial'),
                _buildTableHeader('Scheme'),
                _buildTableHeader('Status'),
              ],
            ),
            // Data rows
            ...users.map((user) {
              UserScheme? userScheme;
              try {
                userScheme = userSchemes.firstWhere(
                  (scheme) => scheme.userId == user.id,
                );
              } catch (e) {
                userScheme = null;
              }
              
              return pw.TableRow(
                children: [
                  _buildTableCell(user.name),
                  _buildTableCell(user.mobileNumber),
                  _buildTableCell(user.serialNumber),
                  _buildTableCell(userScheme?.schemeType.name ?? 'N/A'),
                  _buildTableCell(user.status.toString().split('.').last),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        'Generated by Finance Tracker App\n${DateTime.now().toString()}',
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<void> _saveAndOpenPdfWeb(pw.Document pdf, String reportType) async {
    try {
      final fileName = '${reportType}_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Use printing package for web download
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: fileName,
      );
    } catch (e) {
      debugPrint('Error saving PDF on web: $e');
    }
  }

  static Future<void> _saveAndOpenPdf(pw.Document pdf, String reportType) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${reportType}_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());
      
      // Open the PDF file
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('Error saving PDF: $e');
    }
  }
}
