import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/bottom_nav.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool wifi = true;
  bool notif = true;
  bool sound = true;
  bool vibrate = false;
  bool darkMode = false;

  final TextEditingController deviceNameController =
      TextEditingController(text: 'Sensor Dapur');
  final TextEditingController tempLimitController =
      TextEditingController(text: '40');
  final TextEditingController smokeLimitController =
      TextEditingController(text: '300');

  @override
  void initState() {
    super.initState();
    darkMode = ThemeController.isDark;
  }

  @override
  void dispose() {
    deviceNameController.dispose();
    tempLimitController.dispose();
    smokeLimitController.dispose();
    super.dispose();
  }

  Widget buildInputCard({
    required String label,
    required TextEditingController controller,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg =
        isDark ? const Color(0xFF243041) : const Color(0xFFF8F9FB);
    final cardBg =
        isDark ? const Color(0xFF172131) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.greyText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.darkText,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan $label',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey,
              ),
              suffixText: suffixText,
              suffixStyle: TextStyle(
                color: isDark ? Colors.white70 : AppTheme.greyText,
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSwitchCard({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? const Color(0xFF172131) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryRed,
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.darkText,
          ),
        ),
      ),
    );
  }

  void saveSettings() {
    final deviceName = deviceNameController.text.trim();
    final tempLimit = tempLimitController.text.trim();
    final smokeLimit = smokeLimitController.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Tersimpan: $deviceName | Suhu $tempLimit°C | Asap $smokeLimit ppm',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : AppTheme.darkText;
    final subTextColor =
        isDark ? Colors.white70 : AppTheme.greyText;
    final pageBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: pageBg,
      bottomNavigationBar: BottomNav(currentIndex: 3),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF1E293B), Color(0xFF24364E)]
                      : const [Color(0xFFFF6A5C), Color(0xFFE94B3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppTheme.primaryRed)
                        .withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pengaturan',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Konfigurasi sistem dan notifikasi',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            buildInputCard(
              label: 'Nama Perangkat',
              controller: deviceNameController,
            ),

            buildSwitchCard(
              title: 'WiFi',
              value: wifi,
              onChanged: (v) => setState(() => wifi = v),
            ),
            buildSwitchCard(
              title: 'Notifikasi',
              value: notif,
              onChanged: (v) => setState(() => notif = v),
            ),
            buildSwitchCard(
              title: 'Suara Alarm',
              value: sound,
              onChanged: (v) => setState(() => sound = v),
            ),
            buildSwitchCard(
              title: 'Getar',
              value: vibrate,
              onChanged: (v) => setState(() => vibrate = v),
            ),
            buildSwitchCard(
              title: 'Dark Mode',
              value: darkMode,
              onChanged: (v) {
                setState(() => darkMode = v);
                ThemeController.toggleTheme(v);
              },
            ),

            buildInputCard(
              label: 'Batas Suhu',
              controller: tempLimitController,
              suffixText: '°C',
              keyboardType: TextInputType.number,
            ),
            buildInputCard(
              label: 'Batas Asap',
              controller: smokeLimitController,
              suffixText: 'ppm',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Simpan Pengaturan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}