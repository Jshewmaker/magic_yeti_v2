import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

class TypographyPage extends StatelessWidget {
  const TypographyPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const TypographyPage());
  }

  @override
  Widget build(BuildContext context) {
    final uiTextStyleList = [
      _TextItem(name: 'Display Large', style: UITextStyle.displayLarge),
      _TextItem(name: 'Display Medium', style: UITextStyle.displayMedium),
      _TextItem(name: 'Display Small', style: UITextStyle.displaySmall),
      _TextItem(name: 'Headline Large', style: UITextStyle.headlineLarge),
      _TextItem(name: 'Headline medium', style: UITextStyle.headlineMedium),
      _TextItem(name: 'Headline small', style: UITextStyle.headlineSmall),
      _TextItem(name: 'Title large', style: UITextStyle.titleLarge),
      _TextItem(name: 'Title medium', style: UITextStyle.titleMedium),
      _TextItem(name: 'Label large', style: UITextStyle.titleSmall),
      _TextItem(name: 'Label medium', style: UITextStyle.labelLarge),
      _TextItem(name: 'Label small', style: UITextStyle.labelMedium),
      _TextItem(name: 'Body Text 2', style: UITextStyle.labelSmall),
      _TextItem(name: 'Body large', style: UITextStyle.bodyLarge),
      _TextItem(name: 'Body medium', style: UITextStyle.bodyMedium),
      _TextItem(name: 'Body small', style: UITextStyle.bodySmall),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Typography')),
      body: ListView(
        shrinkWrap: true,
        children: [
          const Center(child: Text('UI Typography')),
          const SizedBox(height: 16),
          ...uiTextStyleList,
        ],
      ),
    );
  }
}

class _TextItem extends StatelessWidget {
  const _TextItem({required this.name, required this.style});

  final String name;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      child: Text(name, style: style),
    );
  }
}
