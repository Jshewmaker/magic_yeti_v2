import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// Shared grid configuration for the stats overview and its skeleton so the
/// two always stay in visual lockstep.
class StatsGrid extends StatelessWidget {
  const StatsGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceInfoProvider.of(context).isPhone;
    return GridView.count(
      crossAxisSpacing: 50,
      childAspectRatio: isPhone ? .8 : 1.2,
      mainAxisSpacing: 10,
      crossAxisCount: 3,
      children: children,
    );
  }
}
