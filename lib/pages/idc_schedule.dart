import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class IdcSchedulePage extends StatelessWidget {
  final Map<String, dynamic> params;

  const IdcSchedulePage({super.key, required this.params});

  String _formatCurrency(double val) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(val);
  }

  // ✅ Helper for safe parsing (Fixes the "3.0" error)
  int _safeInt(dynamic val) {
    if (val == null) return 0;
    return (double.tryParse(val.toString()) ?? 0).toInt();
  }

  @override
  Widget build(BuildContext context) {
    // 1. EXTRACT DATA
    final List idcSchedule = params['idcSchedule'] ?? [];
    final double pl1EMI = (double.tryParse(params['pl1EMI'].toString()) ?? 0);
    final int possessionMonths = _safeInt(params['possessionMonths']);
    final double homeLoanAmount =
        (double.tryParse(params['homeLoanAmount'].toString()) ?? 0);
    final double interestRate =
        (double.tryParse(params['interestRate'].toString()) ?? 9.0);

    // Limits
    final int holdingLimit = _safeInt(params['totalHoldingMonths']);
    final int lastBankDisbursementMonth = _safeInt(
      params['lastBankDisbursementMonth'],
    );

    // ✅ Fix: Use _safeInt inside map/reduce
    final int derivedLastMonth = idcSchedule.isNotEmpty
        ? idcSchedule.map((s) => _safeInt(s['releaseMonth'])).reduce(max)
        : possessionMonths;

    final int fundingEndMonth = lastBankDisbursementMonth > 0
        ? lastBankDisbursementMonth
        : derivedLastMonth;
    // Handle edge case if totalHoldingMonths is 0 (missing), fallback to possession
    final int effectiveHoldingLimit = holdingLimit > 0
        ? holdingLimit
        : possessionMonths;
    final int cutoffMonth = min(fundingEndMonth, effectiveHoldingLimit);

    // 2. FILTER & CALCULATE
    // ✅ Fix: Use _safeInt in filter
    final filteredSchedule = idcSchedule
        .where((row) => _safeInt(row['releaseMonth']) <= cutoffMonth)
        .toList();

    final double disbursementPerSlab = idcSchedule.isNotEmpty
        ? homeLoanAmount / idcSchedule.length
        : 0;
    final double baseSlabInterest =
        (disbursementPerSlab * (interestRate / 100)) / 12;

    double grandTotalInterest = 0;
    for (var row in filteredSchedule) {
      // ✅ Fix: Use _safeInt
      int releaseMonth = _safeInt(row['releaseMonth']);
      int duration = max(0, possessionMonths - releaseMonth);
      grandTotalInterest += (baseSlabInterest * duration);
    }

    final double minMonthlyInterest = filteredSchedule.isNotEmpty
        ? baseSlabInterest
        : 0;
    final double maxMonthlyInterest =
        baseSlabInterest * filteredSchedule.length;

    // 3. UI SETUP
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.grey.shade50;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final text = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          "Construction Schedule",
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: cardBg,
        foregroundColor: text,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Breakdown up to Month $cutoffMonth (Possession)",
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    "Total Interest Cost",
                    grandTotalInterest,
                    Icons.layers,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    "Min Monthly IDC",
                    minMonthlyInterest,
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    "Max Monthly IDC",
                    maxMonthlyInterest,
                    Icons.arrow_upward,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    "Fixed PL1 EMI",
                    pl1EMI,
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    isDark ? Colors.white10 : Colors.grey.shade100,
                  ),
                  columnSpacing: 24,
                  columns: [
                    DataColumn(
                      label: Text(
                        "Pay #",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: text,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Month",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: text,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Disbursement",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: text,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Rate",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: text,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "To Poss.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: text,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Monthly Int.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Total IDC",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.headerLightEnd,
                        ),
                      ),
                    ),
                  ],
                  rows: filteredSchedule.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var row = entry.value;

                    // ✅ Fix: Use _safeInt
                    int slabNo = _safeInt(row['slabNo']);
                    int releaseMonth = _safeInt(row['releaseMonth']);

                    int monthsToPossession = max(
                      0,
                      possessionMonths - releaseMonth,
                    );
                    double cumulativeMonthlyInterest =
                        baseSlabInterest * (idx + 1);
                    double totalCostForSlab =
                        baseSlabInterest * monthsToPossession;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            slabNo.toString(),
                            style: TextStyle(fontSize: 12, color: text),
                          ),
                        ),
                        DataCell(
                          Text(
                            releaseMonth.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: text,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(disbursementPerSlab),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${interestRate.toStringAsFixed(2)}%",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              monthsToPossession.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: text,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(cumulativeMonthlyInterest),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(totalCostForSlab),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.headerLightEnd,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Understanding Outflow",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "The 'Monthly Interest' shown is variable. Add PL1 EMI (${_formatCurrency(pl1EMI)}) to calculate your total monthly check.",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    double value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatCurrency(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
