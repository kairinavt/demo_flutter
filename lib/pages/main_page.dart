import 'package:flutter/material.dart';
import 'package:money_management/pages/category_page.dart';
import 'package:money_management/pages/home_page.dart';
import 'package:money_management/pages/transaction_page.dart';
import 'package:money_management/pages/statistic_page.dart'; // Thêm import này

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late List<Widget> _pages;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      HomePage(key: UniqueKey()),

      CategoryPage(),
      // Thêm trang thống kê
      const StatisticPage(),
    ];
  }

  void refreshHomePage() {
    setState(() {
      _initializePages();
    });
  }

  void onTapped(index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[currentIndex],
      floatingActionButton: Visibility(
        visible: (currentIndex == 0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TransactionPage(
                  refreshHomeCallback: refreshHomePage,
                ),
              ),
            );
          },
          backgroundColor: const Color(0xFF00DDFF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8.0,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                onTapped(0);
              },
              icon: Icon(
                Icons.home_outlined,
                color:
                    currentIndex == 0 ? const Color(0xFF00DDFF) : Colors.grey,
              ),
            ),
            const SizedBox(width: 100),
            IconButton(
              onPressed: () {
                onTapped(1);
              },
              icon: Icon(
                Icons.category_outlined,
                color:
                    currentIndex == 1 ? const Color(0xFF00DDFF) : Colors.grey,
              ),
            ),
            IconButton(
              // Thêm nút thống kê mới
              onPressed: () {
                onTapped(2);
              },
              icon: Icon(
                Icons.bar_chart_outlined, // Icon thống kê
                color:
                    currentIndex == 2 ? const Color(0xFF00DDFF) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
