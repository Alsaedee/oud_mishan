import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomersView extends StatelessWidget {
  const CustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة العملاء')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('قائمة العملاء', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add),
                  label: const Text('إضافة عميل جديد'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: Center(
                child: Text('جاري بناء واجهة إدارة العملاء والولاء...', style: TextStyle(color: AppColors.gold, fontSize: 24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
