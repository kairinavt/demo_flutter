import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_management/database/database_helper.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({Key? key}) : super(key: key);

  @override
  _StatisticPageState createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  int _selectedYear = DateTime.now().year;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _monthlyData = [];
  Map<String, dynamic>? _topExpenseCategory;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final startDate = DateTime(_selectedYear, 1, 1);
    final endDate = DateTime(_selectedYear, 12, 31);

    final summary =
        await DatabaseHelper.instance.getTransactionSummary(startDate, endDate);

    final monthlyData = await DatabaseHelper.instance
        .getMonthlyTransactionSummary(_selectedYear);

    final topExpenseCategory =
        await DatabaseHelper.instance.getTopExpenseCategory(startDate, endDate);

    setState(() {
      _summary = summary;
      _monthlyData = monthlyData;
      _topExpenseCategory = topExpenseCategory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thống kê năm $_selectedYear'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showYearPicker,
          )
        ],
      ),
      body: _summary == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildMonthlyBarChart(),
                const SizedBox(height: 16),
                _buildTopExpenseCategoryCard(),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan tài chính',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
                'Tổng thu nhập', _summary!['totalIncome'], Colors.green),
            _buildStatRow(
                'Tổng chi tiêu', _summary!['totalExpense'], Colors.red),
            _buildStatRow('Số dư', _summary!['netBalance'],
                _summary!['netBalance'] >= 0 ? Colors.blue : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value),
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biểu đồ thu chi hàng tháng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _monthlyData.map((monthData) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        // Thu nhập
                        Container(
                          width: 30,
                          height: monthData['income'] / 1000, // Tỷ lệ cao
                          color: Colors.green,
                        ),
                        // Chi tiêu
                        Container(
                          width: 30,
                          height: monthData['expense'] / 1000, // Tỷ lệ cao
                          color: Colors.red,
                        ),
                        const SizedBox(height: 4),
                        Text('T${monthData['month']}')
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopExpenseCategoryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh mục chi tiêu nhiều nhất',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _topExpenseCategory != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_topExpenseCategory!['categoryName'],
                          style: const TextStyle(fontSize: 16)),
                      Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                              .format(_topExpenseCategory!['total']),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                    ],
                  )
                : const Text('Chưa có dữ liệu'),
          ],
        ),
      ),
    );
  }

  void _showYearPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn năm'),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 5, // Hiển thị 5 năm gần nhất
              itemBuilder: (context, index) {
                final year = DateTime.now().year - index;
                return ListTile(
                  title: Text('Năm $year'),
                  onTap: () {
                    setState(() {
                      _selectedYear = year;
                    });
                    _loadStatistics();
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
