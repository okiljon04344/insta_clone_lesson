import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/app_language_service.dart';
import '../../theme/app_theme.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final _searchController = TextEditingController();
  final _service = AppLanguageService();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locales = [...AppLanguageService.supportedLocales];
    locales.sort(
      (a, b) => _service.labelFor(a).compareTo(_service.labelFor(b)),
    );

    final filtered = locales.where((locale) {
      if (_query.isEmpty) return true;
      final label = _service.labelFor(locale).toLowerCase();
      final code = locale.toLanguageTag().toLowerCase();
      return label.contains(_query) || code.contains(_query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('language_settings'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: AppTheme.bodyStyle,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: context.tr('search_language'),
                prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<Locale>(
              valueListenable: _service.localeNotifier,
              builder: (context, currentLocale, child) {
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final locale = filtered[index];
                    final isSelected =
                        locale.languageCode == currentLocale.languageCode &&
                        locale.countryCode == currentLocale.countryCode;
                    return ListTile(
                      onTap: () async {
                        await _service.setLocale(locale);
                        if (!mounted) return;
                        setState(() {});
                      },
                      title: Text(
                        _service.labelFor(locale),
                        style: AppTheme.bodyStyle,
                      ),
                      subtitle: Text(
                        locale.toLanguageTag(),
                        style: AppTheme.captionStyle,
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppTheme.accent)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
