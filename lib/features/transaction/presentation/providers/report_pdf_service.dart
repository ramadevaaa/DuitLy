import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:duitly/features/transaction/data/models/transaction_model.dart';

class ReportPdfService {
  static Future<void> generateAndPrint(List<TransactionModel> transactions, String userName, String periodLabel) async {
    final pdf = pw.Document();
    
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    double totalIn = 0;
    double totalOut = 0;

    for (var tx in transactions) {
      if (tx.jenisArusKas == 'IN') totalIn += tx.nominal;
      if (tx.jenisArusKas == 'OUT') totalOut += tx.nominal;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('DuitLy Financial Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                    pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('User: $userName', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Period: $periodLabel', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              
              // Summary Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Total Pemasukan', style: const pw.TextStyle(color: PdfColors.green)),
                        pw.Text(currencyFormat.format(totalIn), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ]
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Total Pengeluaran', style: const pw.TextStyle(color: PdfColors.red)),
                        pw.Text(currencyFormat.format(totalOut), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ]
                    ),
                  ]
                ),
              ),
              pw.SizedBox(height: 20),
              
              pw.Text('Rincian Transaksi:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              
              // Table
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Tanggal', 'Judul', 'Tipe', 'Nominal'],
                data: transactions.map((tx) {
                  return [
                    DateFormat('dd/MM/yy HH:mm').format(tx.timeStamp),
                    tx.judulTransaksi,
                    tx.jenisArusKas,
                    currencyFormat.format(tx.nominal),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                },
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'DuitLy_Report.pdf',
    );
  }
}
