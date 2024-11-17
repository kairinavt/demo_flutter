import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:money_management/database/database_helper.dart';

class TransactionPage extends StatefulWidget {
  final VoidCallback refreshHomeCallback;

  const TransactionPage({Key? key, required this.refreshHomeCallback})
      : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  bool isExpense = true;
  int? selectedCategoryId;
  String? description;
  DateTime selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();

  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final loadedCategories =
        await DatabaseHelper.instance.getCategories(isExpense);
    setState(() {
      categories = loadedCategories;
      selectedCategoryId = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.amber[800]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber[800],
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (_amountController.text.isEmpty || selectedCategoryId == null) {
      _showNotification('Please fill in all required fields', isError: true);
      return;
    }

    double amount = double.parse(_amountController.text);
    await DatabaseHelper.instance.createTransaction(
      amount,
      description ?? '',
      selectedCategoryId!,
      selectedDate,
      isExpense,
    );

    _showNotification('Transaction saved successfully');

    widget.refreshHomeCallback();

    Navigator.of(context).pop();
  }

  void _showNotification(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isError ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tạo ',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.amber[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionTypeSwitch(),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 20),
              _buildCategoryDropdown(),
              const SizedBox(height: 20),
              _buildDescriptionField(),
              const SizedBox(height: 20),
              _buildDatePicker(),
              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Dòng tiền ra',
            style: GoogleFonts.poppins(
              color: isExpense ? Colors.red : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          Switch(
            value: isExpense,
            onChanged: (value) {
              setState(() {
                isExpense = value;
                _loadCategories();
              });
            },
            activeColor: Colors.red,
            inactiveTrackColor: Colors.green,
          ),
          Text(
            'Dòng tiền vào',
            style: GoogleFonts.poppins(
              color: !isExpense ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: 'Nhập số tiền',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: Icon(Icons.attach_money, color: Colors.amber[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.amber[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.amber[800]!, width: 2),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedCategoryId,
      hint: Text('Choose Category', style: GoogleFonts.poppins()),
      items: categories.map((category) {
        return DropdownMenuItem<int>(
          value: category['id'] as int,
          child: Text(category['name'], style: GoogleFonts.poppins()),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          selectedCategoryId = newValue;
        });
      },
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: Icon(Icons.category, color: Colors.amber[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.amber[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.amber[800]!, width: 2),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: 'Mô tả',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: Icon(Icons.description, color: Colors.amber[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.amber[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.amber[800]!, width: 2),
        ),
      ),
      onChanged: (value) {
        setState(() {
          description = value;
        });
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ngày',
          labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
          prefixIcon: Icon(Icons.calendar_today, color: Colors.amber[800]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.amber[800]!),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate == null
                  ? 'Chọn ngày'
                  : DateFormat('dd/MM/yyyy').format(selectedDate),
              style: GoogleFonts.poppins(),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.amber[800]),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber[800],
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          'Xác nhận',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
