import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

class ColorsPage extends StatelessWidget {
  const ColorsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ColorsPage());
  }

  @override
  Widget build(BuildContext context) {
    const colorItems = [
      _ColorItem(name: 'Primary', color: AppColors.primary),
      _ColorItem(name: 'Secondary', color: AppColors.secondary),
      _ColorItem(name: 'Tertiary', color: AppColors.tertiary),
      _ColorItem(name: 'Error', color: AppColors.error),
      _ColorItem(name: 'Background', color: AppColors.background),
      _ColorItem(name: 'Surface', color: AppColors.surface),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Colors')),
      body: ListView(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        children: colorItems,
      ),
    );
  }
}

class _ColorItem extends StatelessWidget {
  const _ColorItem({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(name),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _ColorSquare(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSquare extends StatelessWidget {
  const _ColorSquare({required this.color});

  final Color color;

  TextStyle get textStyle {
    return TextStyle(
      color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
    );
  }

  String get hexCode {
    if (color.value.toRadixString(16).length <= 2) {
      return '--';
    } else {
      return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, border: Border.all()),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(child: Text(hexCode, style: textStyle)),
          ),
        ],
      ),
    );
  }
}
