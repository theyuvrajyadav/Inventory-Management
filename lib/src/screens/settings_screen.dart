import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threshold = ref.watch(lowStockThresholdProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Low-stock threshold'),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextFormField(
                  initialValue: threshold.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (v) {
                    final parsed = int.tryParse(v) ?? 5;
                    ref.read(lowStockThresholdProvider.notifier).state = parsed.clamp(0, 9999);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


