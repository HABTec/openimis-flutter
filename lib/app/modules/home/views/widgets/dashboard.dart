import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'help_screen.dart';

class DashboardScreen extends StatelessWidget {
  final List<DashboardItem> items = [
    DashboardItem(name: 'Enrollment', icon: Icons.person_add_alt_1_rounded),
    DashboardItem(name: 'Inquire', icon: Icons.search),
    DashboardItem(name: 'Help', icon: Icons.help),
  ];

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return DashboardCard(item: items[index]);
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

class DashboardItem {
  final String name;
  final IconData icon;

  DashboardItem({required this.name, required this.icon});
}

class DashboardCard extends StatelessWidget {
  final DashboardItem item;

  const DashboardCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4.0,
      child: InkWell(
        onTap: () {
          if (item.name == 'Enrollment') {
            Get.toNamed('/enhanced-enrollment');
          } else if (item.name == 'Inquire') {
            Get.toNamed('/search');
          } else {
            Get.to(() => HelpScreen());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 48.0,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 16.0),
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
