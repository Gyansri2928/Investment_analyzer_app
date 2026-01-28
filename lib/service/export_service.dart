import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  // --- HELPER: FORMAT CURRENCY ---
  static String _fmt(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    final numVal = value is int
        ? value
        : (double.tryParse(value.toString()) ?? 0);
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs. ',
      decimalDigits: 0,
    ).format(numVal);
  }

  static String _fmtLakhs(dynamic value) {
    if (value == null) return '0';
    double val = double.tryParse(value.toString()) ?? 0;
    return "Rs. ${(val / 100000).toStringAsFixed(2)} L";
  }

  // Helper to format "Rate & Term" string safely
  static String _fmtLoanDetails(dynamic rate, dynamic term) {
    if (rate == null || term == null || rate == '' || term == '') return "";
    return "@ $rate% for $term yrs";
  }

  // ===========================================================================
  // 1. EXCEL GENERATION
  // ===========================================================================
  static Future<void> exportToExcel(Map<String, dynamic> data) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Detailed Summary'];
    excel.delete('Sheet1');

    void addRow(
      List<String> cells, {
      bool isHeader = false,
      bool isBold = false,
    }) {
      List<CellValue> rowData = cells.map((e) => TextCellValue(e)).toList();
      sheet.appendRow(rowData);
    }

    // --- DATA POPULATION ---
    addRow(["PROPERTY INVESTMENT ANALYSIS REPORT"], isHeader: true);
    addRow([
      "Generated Date:",
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    ]);
    addRow([""]);

    addRow(["1. PROPERTY & COST DETAILS"], isBold: true);
    addRow(["Property Size", "${data['propertySize']} sq.ft"]);
    addRow(["Purchase Price", "${_fmt(data['purchasePrice'])}/sq.ft"]);
    addRow(["Stamp Duty", _fmt(data['stampDutyCost'])]);
    addRow(["GST", _fmt(data['gstCost'])]);
    addRow(["TOTAL PROPERTY COST", _fmt(data['totalCost'])], isBold: true);
    addRow([""]);

    addRow(["2. FUNDING PLAN"], isBold: true);
    addRow([
      "Down Payment",
      "${data['downPaymentShare']}%",
      _fmt(data['downPaymentAmount']),
    ]);

    // ✅ FIX: Safe Null Check for Home Loan
    addRow([
      "Home Loan",
      "${data['homeLoanShare']}%",
      _fmt(data['homeLoanAmount']),
      _fmtLoanDetails(data['homeLoanRate'], data['homeLoanTerm']),
    ]);

    // ✅ FIX: Added Rate & Tenure for PL1
    if (data['hasPersonalLoan1'] == true) {
      addRow([
        "Personal Loan 1",
        "${data['personalLoan1Share']}%",
        _fmt(data['personalLoan1Amount']),
        _fmtLoanDetails(data['personalLoan1Rate'], data['personalLoan1Term']),
      ]);
    }

    // ✅ FIX: Added Rate & Tenure for PL2
    if (data['hasPersonalLoan2'] == true) {
      addRow([
        "Personal Loan 2",
        "${data['personalLoan2Share']}%",
        _fmt(data['personalLoan2Amount']),
        _fmtLoanDetails(data['personalLoan2Rate'], data['personalLoan2Term']),
      ]);
    }
    addRow([
      "TOTAL CASH INVESTED",
      _fmt(data['totalCashInvested']),
    ], isBold: true);
    addRow([""]);

    addRow(["3. MONTHLY CASH FLOW"], isBold: true);
    addRow(["Home Loan EMI", _fmt(data['homeLoanEMI'])]);
    addRow(["Personal Loan 1 EMI", _fmt(data['personalLoan1EMI'])]);
    addRow(["Avg. IDC (Interest)", _fmt(data['monthlyIDCEMI'])]);
    addRow([
      "Peak Monthly Commitment",
      _fmt(data['postPossessionEMI']),
    ], isBold: true);
    addRow([""]);

    addRow(["4. RETURN ANALYSIS (After ${data['years']} Years)"], isBold: true);
    addRow(["Exit Price", "${_fmt(data['exitPrice'])}/sq.ft"]);
    addRow(["Sale Value", _fmt(data['saleValue'])]);
    addRow(["(-) Outstanding Loan", _fmt(data['totalLoanOutstanding'])]);
    addRow(["(-) Total EMIs Paid", _fmt(data['totalEMIPaid'])]);
    addRow(["(-) Initial Cash", _fmt(data['downPaymentAmount'])]);
    addRow(["NET PROFIT / LOSS", _fmt(data['netGainLoss'])], isBold: true);
    addRow([
      "ROI %",
      "${(data['roi'] as double).toStringAsFixed(2)}%",
    ], isBold: true);

    // --- SAVE AND SHARE ---
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/Property_Analysis_Report.xlsx";
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      await Share.shareXFiles([
        XFile(path),
      ], text: 'Property Analysis Excel Report');
    }
  }

  // ===========================================================================
  // 2. PDF GENERATION
  // ===========================================================================
  static Future<void> exportToPDF(Map<String, dynamic> data) async {
    final doc = pw.Document();

    final headerStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue900,
    );
    final subHeaderStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );
    final tableHeaderStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final smallText = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);
    final cellStyle = pw.TextStyle(fontSize: 10);

    // Helper: Header Row for Table
    pw.TableRow buildTableHeader(List<String> cells) {
      return pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
        children: cells
            .map(
              (c) => pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  c,
                  style: tableHeaderStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            )
            .toList(),
      );
    }

    // Helper: Data Row for Table
    pw.TableRow buildTableRow(List<String> cells) {
      return pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        children: cells
            .map(
              (c) => pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  c,
                  style: cellStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            )
            .toList(),
      );
    }

    // --- PAGE 1 ---
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Property Investment Analyzer",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      "Generated on ${DateFormat('dd/MM/yyyy, HH:mm').format(DateTime.now())}",
                      style: smallText,
                    ),
                  ],
                ),
                pw.Text(
                  "Agenthum AI",
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 10),

            // 2. EXECUTIVE SUMMARY
            pw.Text("1. Executive Summary", style: headerStyle),
            pw.SizedBox(height: 10),

            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Property Details", style: subHeaderStyle),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "Size: ${data['propertySize']} sq.ft",
                          style: cellStyle,
                        ),
                        pw.Text(
                          "Rate: ${_fmt(data['purchasePrice'])}/sq.ft",
                          style: cellStyle,
                        ),
                        pw.Text(
                          "Possession: ${data['possessionMonths']} Months",
                          style: cellStyle,
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Financial Overview", style: subHeaderStyle),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Total Cost:", style: cellStyle),
                            pw.Text(
                              _fmtLakhs(data['totalCost']),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Investment:", style: cellStyle),
                            pw.Text(
                              _fmtLakhs(data['totalCashInvested']),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Net Profit:", style: cellStyle),
                            pw.Text(
                              _fmtLakhs(data['netGainLoss']),
                              style: pw.TextStyle(
                                color: PdfColors.green700,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("ROI:", style: cellStyle),
                            pw.Text(
                              "${(data['roi'] as double).toStringAsFixed(1)}%",
                              style: pw.TextStyle(
                                color: PdfColors.green700,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // 3. TIMELINE 1
            pw.Text("2. Timeline & Cash Flow Breakdown", style: headerStyle),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              color: PdfColors.blue50,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Timeline 1: Pre-Possession (0 - ${data['possessionMonths']} Months)",
                    style: subHeaderStyle,
                  ),
                  pw.Text(
                    "Total Paid: ${_fmt(data['prePossessionTotal'])}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Table(
              border: null,
              children: [
                // ✅ FIX: Removed 'Total Impact' Column
                buildTableHeader(["Component", "Monthly Amount", "Duration"]),
                if (data['hasPersonalLoan1'] == true)
                  buildTableRow([
                    "Personal Loan 1 EMI",
                    _fmt(data['personalLoan1EMI']),
                    "${data['prePossessionMonths']} Mo",
                  ]),
                if (data['hasIDC'] == true)
                  buildTableRow([
                    "Avg. IDC (Interest)",
                    _fmt(data['monthlyIDCEMI']),
                    "${data['constructionMonths']} Mo",
                  ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // 4. TIMELINE 2
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              color: PdfColors.green50,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Timeline 2: Post-Possession (${data['postPossessionMonths']} Months)",
                    style: subHeaderStyle,
                  ),
                  pw.Text(
                    "Total Paid: ${_fmt(data['postPossessionTotal'])}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Table(
              children: [
                // ✅ FIX: Removed 'Total Paid' Column
                buildTableHeader(["Loan Type", "Monthly EMI", "Start Month"]),
                buildTableRow([
                  "Home Loan",
                  _fmt(data['homeLoanEMI']),
                  "Month ${data['homeLoanStartMonth']}",
                ]),
                if (data['hasPersonalLoan1'] == true)
                  buildTableRow([
                    "Personal Loan 1",
                    _fmt(data['personalLoan1EMI']),
                    "Month ${data['pl1StartMonth']}",
                  ]),
                if (data['hasPersonalLoan2'] == true)
                  buildTableRow([
                    "Personal Loan 2",
                    _fmt(data['personalLoan2EMI']),
                    "Month ${data['pl2StartMonth']}",
                  ]),

                // Combined Total Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        "COMBINED TOTAL",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        _fmt(data['postPossessionEMI']),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text("-", textAlign: pw.TextAlign.center),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // 5. COMPREHENSIVE METRICS
            pw.Text("3. Comprehensive Financial Metrics", style: headerStyle),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricBox(
                  "Peak Commitment",
                  _fmt(data['postPossessionEMI']),
                ),
                _buildMetricBox(
                  "Total Interest",
                  _fmtLakhs(data['totalInterestPaid']),
                ),
                _buildMetricBox("Total EMI Paid", _fmt(data['totalEMIPaid'])),
                _buildMetricBox(
                  "Total Outstanding",
                  _fmt(data['totalLoanOutstanding']),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricBox(
                  "Leftover Cash",
                  _fmtLakhs(data['leftoverCash']),
                  isHighlight: true,
                ),
                _buildMetricBox(
                  "Net Position",
                  _fmtLakhs(data['netGainLoss']),
                  isHighlight: true,
                ),
              ],
            ),
          ];
        },
      ),
    );

    // --- PAGE 2 ---
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 6. IDC ANALYSIS
            if (data['hasIDC'] == true) ...[
              pw.Text(
                "3. IDC (Interest During Construction) Analysis",
                style: headerStyle,
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                children: [
                  buildTableHeader([
                    "Slab #",
                    "Month",
                    "Disbursement",
                    "Interest Cost",
                  ]),
                  ...(data['idcSchedule'] as List).map((slab) {
                    return buildTableRow([
                      "${slab['slabNo']}",
                      "Month ${slab['releaseMonth']}",
                      _fmt(slab['amount']),
                      _fmt(slab['interestCost']),
                    ]);
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    "Total IDC: ${_fmtLakhs(data['totalIDC'])}",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // 7. SMART SAVER COMPARISON (Redesigned)
            if (data['strategyComparison'] != null) ...[
              pw.Text("4. Smart Saver Strategy Comparison", style: headerStyle),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey50,
                    ),
                    children: [
                      // ✅ FIX: Removed confusing extra columns. Now just 3 simple columns.
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          "Description",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          "Standard CLP",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          "Smart Saver",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  buildTableRow([
                    "Total Paid till Possession",
                    _fmt(data['strategyComparison']['stdTotal']),
                    "${_fmt(data['strategyComparison']['smartTotal'])} (Pay Extra: ${_fmt((data['strategyComparison']['smartTotal'] - data['strategyComparison']['stdTotal']))})",
                  ]),
                  buildTableRow([
                    "Loan Balance at Possession",
                    _fmtLakhs(data['strategyComparison']['stdBalance']),
                    "${_fmtLakhs(data['strategyComparison']['smartBalance'])} (Saved: ${_fmtLakhs(data['strategyComparison']['savings'])})",
                  ]),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // 8. EXIT PRICE SCENARIOS
            pw.Text("5. Exit Price Scenarios", style: headerStyle),
            pw.SizedBox(height: 10),
            pw.Table(
              children: [
                buildTableHeader([
                  "Scenario",
                  "Exit Price",
                  "Sale Value",
                  "Profit/Loss",
                  "ROI",
                ]),
                ...(data['multipleScenarios'] as List).map((sc) {
                  return buildTableRow([
                    sc['isSelected'] ? "Selected" : "Scenario",
                    _fmt(sc['exitPrice']),
                    _fmtLakhs(sc['saleValue']),
                    _fmtLakhs(sc['netProfit']),
                    "${(sc['roi'] as double).toStringAsFixed(1)}%",
                  ]);
                }).toList(),
              ],
            ),

            // FOOTER
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.Text(
              "Disclaimer: This report is for estimation purposes only. Actual values may vary based on bank rates, taxes, and market conditions.",
              style: smallText,
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              "Generated by Agenthum AI",
              style: pw.TextStyle(color: PdfColors.blue, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Property_Report.pdf',
    );
  }

  // --- PDF WIDGET HELPERS ---
  static pw.Widget _buildMetricBox(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: isHighlight ? PdfColors.green50 : PdfColors.grey100,
        border: pw.Border.all(
          color: isHighlight ? PdfColors.green : PdfColors.grey400,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: isHighlight ? PdfColors.green900 : PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}
