import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fix_mate/admin/admin_layout.dart';

class a_Dashboard extends StatefulWidget {
  static String routeName = "/admin/contact_developer";

  @override
  _a_DashboardState createState() => _a_DashboardState();
}

class _a_DashboardState extends State<a_Dashboard> {
  final List<Map<String, dynamic>> providers = [
    {
      "name": "Cheong Electrical Service Ctr.",
      "jobs": 3,
      "revenue": 440.0,
      "commission": 22.0,
      "amountToTransfer": 418.0,
      "transferStatus": "Paid"
    },
    {
      "name": "TY Speciality Roofing & Plumbing Works",
      "jobs": 33,
      "revenue": 2640.0,
      "commission": 264.0,
      "amountToTransfer": 2376.0,
      "transferStatus": "Pending"
    },
    {
      "name": "CY Roofing Sdn Bhd",
      "jobs": 18,
      "revenue": 1440.0,
      "commission": 144.0,
      "amountToTransfer": 1296.0,
      "transferStatus": "Paid"
    },
  ];


  final Map<String, Map<String, dynamic>> monthlySummary = {
    "June 2025": {"revenue": 4520.0, "bookings": 54.0, "commission": 430.0},
    "May 2025": {"revenue": 2500.0, "bookings": 40.0, "commission": 300.0},
  };

  String selectedMonth = "June 2025";

  double getPercentageChange(double current, double previous) {
    if (previous == 0) return 100.0;
    return ((current - previous) / previous) * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final current = monthlySummary[selectedMonth]!;
    final previousKey = selectedMonth == "June 2025" ? "May 2025" : "June 2025";
    final previous = monthlySummary[previousKey]!;

    return AdminLayout(
        selectedIndex: 2,
      child: Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9342),
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,),
        ),
        titleSpacing: 25,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(current),
            const SizedBox(height: 24),
            _buildMonthComparison(current, previous),
            const SizedBox(height: 24),
            _buildRevenueChart(),
            const SizedBox(height: 24),
            _buildProviderTable(),
            const SizedBox(height: 24),
            _buildPendingPayoutsTable(),
          ],
        ),
      ),
      )
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> current) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center, // Ensures multiple rows are centered
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildCard("Total Revenue", "RM ${current["revenue"]}", Icons.attach_money, Colors.green),
          _buildCard("Total Commission", "RM ${current["commission"]}", Icons.receipt_long, Colors.blue),
          _buildCard("Total Bookings", "${current["bookings"]}", Icons.book_online, Colors.deepPurple),
          _buildCard("Top Provider", "FixPro Services", Icons.star, Colors.orange),
        ],
      ),
    );
  }


  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMonthComparison(Map<String, dynamic> current, Map<String, dynamic> previous) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Month-over-Month Comparison",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF464E65)),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: FixedColumnWidth(120),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(padding: EdgeInsets.all(8), child: Text("Metric", style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8), child: Text("Change", style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8), child: Text("Current")),
                    Padding(padding: EdgeInsets.all(8), child: Text("Previous")),
                  ],
                ),
                ...[
                  ["Revenue", current["revenue"], previous["revenue"]],
                  ["Bookings", current["bookings"], previous["bookings"]],
                  ["Commission", current["commission"], previous["commission"]],
                ].map((row) {
                  final change = getPercentageChange(
                    (row[1] as num).toDouble(),
                    (row[2] as num).toDouble(),
                  );
                  final isUp = change >= 0;
                  final emoji = isUp ? '📈' : '📉';

                  return TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(8), child: Text(row[0])),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          "$emoji ${isUp ? '+' : ''}${change.toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: isUp ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.all(8), child: Text(row[1].toString())),
                      Padding(padding: const EdgeInsets.all(8), child: Text(row[2].toString())),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final List<double> monthlyRevenue = [3000, 4200, 3000, 3500, 2500, 3184];
    final List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Monthly Revenue Trend",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF464E65))),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: List.generate(6, (i) => BarChartGroupData(x: i, barRods: [
                  BarChartRodData(toY: monthlyRevenue[i].toDouble(), color: Color(0xFFFF9342),  width: 18),
                ])),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(months[value.toInt()], style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: 500,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('0');
                          case 1000:
                            return const Text('1K');
                          case 2000:
                            return const Text('2K');
                          case 3000:
                            return const Text('3K');
                          case 4000:
                            return const Text('4K');
                          default:
                            return const SizedBox.shrink(); // Don't show other values
                        }
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Provider Performance (May 2025)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF464E65))),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Provider")),
                DataColumn(label: Text("Jobs")),
                DataColumn(label: Text("Revenue")),
                DataColumn(label: Text("Commission")),
                DataColumn(label: Text("To Transfer")),
                DataColumn(label: Text("Status")),
              ],
              rows: providers.map((p) {
                final bool isPaid = p["transferStatus"] == "Paid";
                return DataRow(cells: [
                  DataCell(Text(p["name"])),
                  DataCell(Text(p["jobs"].toString())),
                  DataCell(Text("RM ${p["revenue"].toStringAsFixed(2)}")),
                  DataCell(Text("RM ${p["commission"].toStringAsFixed(2)}")),
                  DataCell(Text("RM ${p["amountToTransfer"].toStringAsFixed(2)}")),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPaid ? "Paid" : "Pending",
                      style: TextStyle(
                        color: isPaid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )),
                ]);
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
  Widget _buildPendingPayoutsTable() {
    final pendingProviders = providers.where((p) => p["transferStatus"] == "Pending").toList();

    if (pendingProviders.isEmpty) {
      return const Text("✅ All providers have been paid for May 2025.");
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pending Payouts (May 2025)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF464E65))),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Provider")),
                DataColumn(label: Text("To Transfer")),
                DataColumn(label: Text("Payout")),
              ],
              rows: pendingProviders.map((p) {
                return DataRow(cells: [
                  DataCell(Text(p["name"])),
                  DataCell(Text("RM ${p["amountToTransfer"].toStringAsFixed(2)}")),
                  DataCell(
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          p["transferStatus"] = "Paid";
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white, // <-- White text
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text("Mark as Paid"),
                    ),
                  ),


                ]);
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}