import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class p_Revenue extends StatefulWidget {
  @override
  _p_RevenueState createState() => _p_RevenueState();
}

class _p_RevenueState extends State<p_Revenue> {
  String selectedMonth = "June 2025";
  final DateTime today = DateTime.now();
  bool isExpanded = false;

  List<Map<String, dynamic>> _getFilteredCommissions(Map<String, dynamic> current) {
    final commissions = current["commissions"] as List<dynamic>;

    return commissions
        .cast<Map<String, dynamic>>()
        .where((item) =>
    (item["type"] == "Promotion" && item["status"] == "Confirmed") ||
        item["type"] == "Instant")
        .toList();
  }



  final Map<String, Map<String, dynamic>> revenueData = {
    "June 2025": {
      "total": "RM 440",
      "commission": "RM 22",
      "net": "RM 418",
      "promo": 1,
      "instant": 2,
      "topJob": "Water Heater Installation",
      "topJobCount": 2,
      "commissions": [
        {"id": "BKIB-A000025", "title": "Water Heater Installation", "amount": "RM 120", "commission": "RM 6.00", "status": "Paid", "date": "2025-06-05", "type": "Instant"},
        {"id": "BKIB-A000026", "title": "Water Heater Installation", "amount": "RM 120", "commission": "RM 6.00", "status": "Paid", "date": "2025-06-12", "type": "Instant"},
        {"id": "BKIB-A000027", "title": "Auto Gateways Installation", "amount": "RM 200", "commission": "RM 10.00", "status": "Pending", "date": "2025-06-18", "type": "Instant"},
      ],
    },
    "May 2025": {
      "total": "RM 412.50",
      "commission": "RM 23",
      "net": "RM 389.50",
      "promo": 3,
      "instant": 3,
      "topJob": "Light Bulb Installation",
      "topJobCount": 2,
      "commissions": [
        {"id": "BKPR-A000036", "title": "Light Bulb Installation", "amount": "RM 20", "commission": "RM 1.00", "status": "Paid", "date": "2025-05-02", "type": "Promotion"},
        {"id": "BKPR-A000037", "title": "Light Bulb Installation", "amount": "RM 20", "commission": "RM 1.00", "status": "Paid", "date": "2025-05-10", "type": "Promotion"},
        {"id": "BKIB-A000018", "title": "Water Heater Installation", "amount": "RM 120", "commission": "RM 6.00", "status": "Paid", "date": "2025-05-12", "type": "Instant"},
        {"id": "BKIB-A000019", "title": "Auto Gateways Installation", "amount": "RM 200", "commission": "RM 10.00", "status": "Paid", "date": "2025-05-15", "type": "Instant"},
        {"id": "BKIB-A000020", "title": "Water Heater Service Checking", "amount": "RM 50", "commission": "RM 2.50", "status": "Paid", "date": "2025-05-20", "type": "Instant"},
        {"id": "BKPR-A000039", "title": "Pipe Repairing", "amount": "RM 50", "commission": "RM 2.50", "status": "Paid", "date": "2025-05-27", "type": "Promotion"},
      ],
    }
  };

  bool isMonthEnded(String month) {
    try {
      final parsedDate = DateFormat("MMMM yyyy").parse(month);
      final lastDay = DateTime(parsedDate.year, parsedDate.month + 1, 0);
      return today.isAfter(lastDay);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = revenueData[selectedMonth]!;
    final bool canPayCommission = isMonthEnded(selectedMonth);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF464E65),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Revenue",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector Card
            _buildMonthSelectorCard(),

            const SizedBox(height: 20),

            // Summary Cards Section
            _buildSummarySection(current, canPayCommission),

            const SizedBox(height: 24),

            // Job Breakdown Chart
            _buildJobBreakdownSection(current),

            const SizedBox(height: 24),

            // Most Booked Job Section
            _buildMostBookedJobSection(current),

            const SizedBox(height: 24),

            // Commission Breakdown Section
            _buildCommissionBreakdownSection(current, canPayCommission),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6C7CE7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF6C7CE7),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Period",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                DropdownButton<String>(
                  value: selectedMonth,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF464E65),
                  ),
                  items: revenueData.keys
                      .map((month) => DropdownMenuItem(
                    value: month,
                    child: Text(month),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedMonth = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(Map<String, dynamic> current, bool canPayCommission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Revenue Overview",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF464E65),
          ),
        ),
        const SizedBox(height: 12),

        // Summary Cards
        _buildSummaryCard(
          "Total Revenue",
          current["total"],
          const Color(0xFF10B981),
          Icons.trending_up_rounded,
        ),
        _buildSummaryCard(
          "Commission Due",
          current["commission"],
          const Color(0xFFEF4444),
          Icons.remove_circle_outline_rounded,
        ),
        _buildSummaryCard(
          "Net Earnings",
          current["net"],
          const Color(0xFF6C7CE7),
          Icons.account_balance_wallet_rounded,
          isHighlighted: true,
        ),

        const SizedBox(height: 12),

          // Earnings Payout Status
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (() {
              final filtered = _getFilteredCommissions(current);
              final allPaid = filtered.isNotEmpty && filtered.every((item) => item["status"] == "Paid");
              return allPaid
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFFF59E0B).withOpacity(0.1);
            })(),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (() {
                final filtered = _getFilteredCommissions(current);
                final allPaid = filtered.isNotEmpty && filtered.every((item) => item["status"] == "Paid");
                return allPaid
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : const Color(0xFFF59E0B).withOpacity(0.3);
              })(),
            ),
          ),
          child: Row(
            children: [
              Builder(builder: (context) {
                final filtered = _getFilteredCommissions(current);
                final allPaid = filtered.isNotEmpty && filtered.every((item) => item["status"] == "Paid");
                return Icon(
                  allPaid ? Icons.check_circle_rounded : Icons.access_time_rounded,
                  color: allPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final filtered = _getFilteredCommissions(current);
                    final allPaid = filtered.isNotEmpty && filtered.every((item) => item["status"] == "Paid");

                    String message;
                    Color messageColor;

                    if (allPaid) {
                      message = "Your earnings for this month have been successfully paid. Please check your email for the payment evidence from FixMate.";
                      messageColor = const Color(0xFF10B981);
                    } else {
                      final month = selectedMonth.split(" ")[0];
                      message = "Your earnings (after commission deduction) will be paid after $month 30.";
                      messageColor = const Color(0xFFF59E0B);
                    }

                    return Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: messageColor,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        )



        // if (canPayCommission) ...[
        //   const SizedBox(height: 12),
        //   Builder(
        //     builder: (context) {
        //       final filtered = _getFilteredCommissions(current);
        //       final allPaid = filtered.isNotEmpty && filtered.every((item) => item["status"] == "Paid");
        //
        //       return Align(
        //         alignment: Alignment.centerRight,
        //         child: Opacity(
        //           opacity: allPaid ? 0.8 : 1.0,
        //           child: ElevatedButton.icon(
        //             onPressed: allPaid
        //                 ? null
        //                 : () {
        //               // 🔔 Your payment logic here
        //             },
        //             icon: const Icon(Icons.payment_rounded, size: 18),
        //             label: const Text("Pay Commission Now"),
        //             style: ElevatedButton.styleFrom(
        //               backgroundColor: const Color(0xFF6C7CE7),
        //               foregroundColor: Colors.white,
        //               elevation: 2,
        //               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        //               shape: RoundedRectangleBorder(
        //                 borderRadius: BorderRadius.circular(25),
        //               ),
        //             ),
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // ],

      ],
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon, {bool isHighlighted = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: color.withOpacity(0.3))
            : Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          Text(
            amount,
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

  Widget _buildJobBreakdownSection(Map<String, dynamic> current) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C7CE7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF6C7CE7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Job Breakdown",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF464E65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = constraints.maxWidth;
                final chartHeight = 180.0; // Available height for the chart
                final maxValue = (current["promo"] > current["instant"] ? current["promo"] : current["instant"]) * 1.2;

                return Stack(
                  children: [
                    BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [
                            BarChartRodData(
                              toY: current["promo"] * 1.0,
                              color: const Color(0xFF6C7CE7),
                              width: 24,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            )
                          ]),
                          BarChartGroupData(x: 1, barRods: [
                            BarChartRodData(
                              toY: current["instant"] * 1.0,
                              color: const Color(0xFFFF8A65),
                              width: 24,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            )
                          ]),
                        ],
                        maxY: maxValue,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text(
                                      "Promotion",
                                      style: TextStyle(
                                        color: Color(0xFF464E65),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    );
                                  case 1:
                                    return const Text(
                                      "Instant",
                                      style: TextStyle(
                                        color: Color(0xFF464E65),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    );
                                }
                                return const Text("");
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 2,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                    // Value labels positioned exactly at the top of bars
                    if (current["promo"] > 0)
                      Positioned(
                        right: chartWidth * 0.69 - 3, // Center the label on the first bar
                        top: 20 + (chartHeight * (1 - (current["promo"] / maxValue))) - 30, // Position at top of bar
                          child: Text(
                            current["promo"].toString(),
                            style: const TextStyle(
                              color: Color(0xFF6C7CE7),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    if (current["instant"] > 0)
                      Positioned(
                        left: chartWidth * 0.75 - 2, // Adjusted to center the text above the bar
                        top: 20 + (chartHeight * (1 - (current["instant"] / maxValue))) - 35, // Slightly above the bar
                        child: Text(
                          current["instant"].toString(),
                          style: const TextStyle(
                            color: Color(0xFFFF8A65),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostBookedJobSection(Map<String, dynamic> current) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Most Booked Job",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF464E65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current["topJob"],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF464E65),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Booked ${current["topJobCount"]} times in $selectedMonth",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${current["topJobCount"]}x",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionBreakdownSection(Map<String, dynamic> current, bool canPayCommission) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF464E65).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF464E65),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Commission Breakdown",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF464E65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Scrollbar(
            thumbVisibility: true,
            thickness: 4,
            radius: const Radius.circular(4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFF464E65).withOpacity(0.1),
                ),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF464E65),
                  fontSize: 12,
                ),
                dataTextStyle: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 12,
                ),
                columnSpacing: 20,
                horizontalMargin: 0,
                columns: const [
                  DataColumn(label: Text("Booking ID")),
                  DataColumn(label: Text("Job Title")),
                  DataColumn(label: Text("Type")),
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Amount")),
                  DataColumn(label: Text("Commission")),
                  DataColumn(label: Text("Status")),
                ],
                rows: [
                  for (final item in (isExpanded
                      ? current["commissions"]
                      : current["commissions"].take(5)))
                    DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C7CE7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item["id"],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C7CE7),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: Text(
                              item["title"],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item["type"] == "Promotion"
                                  ? const Color(0xFF6C7CE7).withOpacity(0.1)
                                  : const Color(0xFFFF8A65).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item["type"],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: item["type"] == "Promotion"
                                    ? const Color(0xFF6C7CE7)
                                    : const Color(0xFFFF8A65),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            DateFormat("MMM dd").format(DateTime.parse(item["date"])),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            item["amount"],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            item["commission"],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (canPayCommission ? item["status"] : "Pending") == "Paid"
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              canPayCommission ? item["status"] : "Pending",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: (canPayCommission ? item["status"] : "Pending") == "Paid"
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              icon: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF6C7CE7),
              ),
              label: Text(
                isExpanded ? "Show Less" : "View All",
                style: const TextStyle(
                  color: Color(0xFF6C7CE7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}