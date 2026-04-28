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
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: Text(
          context.tr('language_settings'),
          style: const TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.white),
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: context.tr('search_language'),
                  hintStyle: const TextStyle(color: AppTheme.grey),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<Locale>(
              valueListenable: _service.localeNotifier,
              builder: (context, currentLocale, child) {
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: AppTheme.divider,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
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
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        locale.toLanguageTag(),
                        style: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppTheme.blue)
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
