import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    final itemPadding = const EdgeInsets.symmetric(vertical: 8);
    final iconBg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF232325) : Colors.grey[200];
    final iconRadius = 18.0;
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w500,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[700],
      fontSize: 15,
    );
    final headingStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
    );
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.light 
          ? Colors.white 
          : Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        children: [
          Padding(
            padding: sectionPadding,
            child: Text('Appearance', style: headingStyle),
          ),
          Padding(
            padding: sectionPadding.copyWith(top: 0, bottom: 0),
            child: Column(
              children: [
                // Theme row with toggle switch
                _SettingsListItem(
                  icon: Icons.brightness_6,
                  iconBg: iconBg,
                  iconRadius: iconRadius,
                  title: 'Theme',
                  trailing: Switch(
                    value: themeProvider.mode == AppThemeMode.dark,
                    onChanged: (val) {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .setTheme(val ? AppThemeMode.dark : AppThemeMode.light);
                    },
                    activeColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.blueAccent,
                    inactiveThumbColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[400],
                    inactiveTrackColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                  ),
                  padding: itemPadding,
                ),
                _SettingsListItem(
                  icon: Icons.language,
                  iconBg: iconBg,
                  iconRadius: iconRadius,
                  title: 'Language',
                  trailing: Text('English', style: labelStyle),
                  padding: itemPadding,
                ),
                _SettingsListItem(
                  icon: Icons.palette,
                  iconBg: iconBg,
                  iconRadius: iconRadius,
                  title: 'Color Scheme',
                  trailing: Text('Default', style: labelStyle),
                  padding: itemPadding,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: sectionPadding,
            child: Text('Notifications', style: headingStyle),
          ),
          Padding(
            padding: sectionPadding.copyWith(top: 0, bottom: 0),
            child: Column(
              children: [
                _SettingsToggleItem(
                  icon: Icons.notifications_active,
                  iconBg: iconBg,
                  iconRadius: iconRadius,
                  title: 'Push Notifications',
                  value: true,
                  onChanged: null,
                  padding: itemPadding,
                ),
                _SettingsToggleItem(
                  icon: Icons.wb_sunny,
                  iconBg: iconBg,
                  iconRadius: iconRadius,
                  title: 'Morning Briefings',
                  value: false,
                  onChanged: null,
                  padding: itemPadding,
                ),
                _SettingsToggleItem(
                  icon: Icons.emoji_events,
                  iconBg: iconBg,
                  iconRadius: iconRadius,
                  title: 'Track Study Streaks',
                  value: true,
                  onChanged: null,
                  padding: itemPadding,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsListItem extends StatelessWidget {
  final IconData icon;
  final Color? iconBg;
  final double iconRadius;
  final String title;
  final Widget trailing;
  final EdgeInsets padding;
  const _SettingsListItem({
    required this.icon,
    required this.iconBg,
    required this.iconRadius,
    required this.title,
    required this.trailing,
    required this.padding,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(iconRadius),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            )),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SettingsToggleItem extends StatelessWidget {
  final IconData icon;
  final Color? iconBg;
  final double iconRadius;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsets padding;
  const _SettingsToggleItem({
    required this.icon,
    required this.iconBg,
    required this.iconRadius,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.padding,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(iconRadius),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            )),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.blueAccent,
            inactiveThumbColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[400],
            inactiveTrackColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
          ),
        ],
      ),
    );
  }
} 