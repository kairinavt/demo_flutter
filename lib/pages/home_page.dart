import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:money_management/database/database_helper.dart';
import 'package:calendar_appbar/calendar_appbar.dart';
import 'package:money_management/pages/transaction_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? refreshCallback;

  const HomePage({Key? key, this.refreshCallback}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();

  static const routeName = '/home';
}

class _HomePageState extends State<HomePage> {
  final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Số tiền ', decimalDigits: 0);

  double balance = 0;
  double monthlyIncome = 0;
  double monthlyExpense = 0;
  List<Map<String, dynamic>> transactions = [];
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _calculateBalance();
    await _calculateMonthlyIncomeAndExpense();
    await _loadTransactions();
  }

  Future<void> _calculateBalance() async {
    final allTransactions = await DatabaseHelper.instance.getTransactions();
    double totalBalance = 0;
    for (var transaction in allTransactions) {
      if (transaction['isExpense'] == 0) {
        totalBalance += transaction['amount'];
      } else {
        totalBalance -= transaction['amount'];
      }
    }
    setState(() {
      balance = totalBalance;
    });
  }

  Future<void> _calculateMonthlyIncomeAndExpense() async {
    final allTransactions = await DatabaseHelper.instance.getTransactions();
    double income = 0;
    double expense = 0;
    final now = DateTime.now();
    for (var transaction in allTransactions) {
      final transactionDate = DateTime.parse(transaction['date']);
      if (transactionDate.year == now.year &&
          transactionDate.month == now.month) {
        if (transaction['isExpense'] == 0) {
          income += transaction['amount'];
        } else {
          expense += transaction['amount'];
        }
      }
    }
    setState(() {
      monthlyIncome = income;
      monthlyExpense = expense;
    });
  }

  Future<void> _loadTransactions() async {
    final allTransactions = await DatabaseHelper.instance.getTransactions();
    setState(() {
      transactions = allTransactions.where((transaction) {
        final transactionDate = DateTime.parse(transaction['date']);
        return transactionDate.year == selectedDate.year &&
            transactionDate.month == selectedDate.month &&
            transactionDate.day == selectedDate.day;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CalendarAppBar(
        backButton: false,
        accent: Colors.amber[800],
        locale: 'id',
        onDateChanged: (value) {
          setState(() {
            selectedDate = value;
          });
          _loadTransactions();
        },
        firstDate: DateTime.now().subtract(const Duration(days: 140)),
        lastDate: DateTime.now(),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(),
                const SizedBox(height: 25),
                _buildTransactionHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[700]!, Colors.amber[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đỗ Văn Khải',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currencyFormatter.format(balance),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceItem(Icons.arrow_downward, Colors.green, 'Thu nhập',
                  monthlyIncome),
              _buildBalanceItem(
                  Icons.arrow_upward, Colors.red, 'Đầu ra', monthlyExpense),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
      IconData icon, Color color, String label, double amount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              currencyFormatter.format(amount),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử giao dịch',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        transactions.isEmpty
            ? const Center(child: Text('Không có giao dịch nào vào ngày này'))
            : Column(
                children: transactions
                    .map((transaction) => _buildTransactionItem(
                          transaction['description'],
                          transaction['amount'],
                          transaction['isExpense'] == 1,
                          transaction['categoryName'],
                        ))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildTransactionItem(
      String description, double amount, bool isExpense, String category) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isExpense ? Colors.red[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          currencyFormatter.format(amount),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
            Text(
              category,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
