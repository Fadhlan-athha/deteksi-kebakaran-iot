import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseReference _settingsRef =
      FirebaseDatabase.instance.ref('settings/device_1');

  final TextEditingController namaPerangkatController =
      TextEditingController();

  final TextEditingController batasSuhuWaspadaController =
      TextEditingController();

  final TextEditingController batasSuhuDaruratController =
      TextEditingController();

  final TextEditingController batasAsapWaspadaController =
      TextEditingController();

  final TextEditingController batasAsapDaruratController =
      TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool buzzerAktif = true;

  ThemeMode selectedThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    namaPerangkatController.dispose();
    batasSuhuWaspadaController.dispose();
    batasSuhuDaruratController.dispose();
    batasAsapWaspadaController.dispose();
    batasAsapDaruratController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final snapshot = await _settingsRef.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map;

      namaPerangkatController.text =
          data['namaPerangkat']?.toString() ?? 'Ruang 1';

      batasSuhuWaspadaController.text =
          data['batasSuhuWaspada']?.toString() ?? '35';

      batasSuhuDaruratController.text =
          data['batasSuhuDarurat']?.toString() ?? '45';

      batasAsapWaspadaController.text =
          data['batasAsapWaspada']?.toString() ?? '2500';

      batasAsapDaruratController.text =
          data['batasAsapDarurat']?.toString() ?? '3500';

      buzzerAktif = data['buzzerAktif'] == true;
    } else {
      namaPerangkatController.text = 'Ruang 1';
      batasSuhuWaspadaController.text = '35';
      batasSuhuDaruratController.text = '45';
      batasAsapWaspadaController.text = '2500';
      batasAsapDaruratController.text = '3500';
      buzzerAktif = true;

      await _saveSettings(showMessage: false);
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveSettings({bool showMessage = true}) async {
    setState(() {
      isSaving = true;
    });

    final String namaPerangkat = namaPerangkatController.text.trim();

    final double batasSuhuWaspada =
        double.tryParse(batasSuhuWaspadaController.text.trim()) ?? 35.0;

    final double batasSuhuDarurat =
        double.tryParse(batasSuhuDaruratController.text.trim()) ?? 45.0;

    final int batasAsapWaspada =
        int.tryParse(batasAsapWaspadaController.text.trim()) ?? 2500;

    final int batasAsapDarurat =
        int.tryParse(batasAsapDaruratController.text.trim()) ?? 3500;

    await _settingsRef.set({
      'namaPerangkat': namaPerangkat.isEmpty ? 'Ruang 1' : namaPerangkat,
      'batasSuhuWaspada': batasSuhuWaspada,
      'batasSuhuDarurat': batasSuhuDarurat,
      'batasAsapWaspada': batasAsapWaspada,
      'batasAsapDarurat': batasAsapDarurat,
      'buzzerAktif': buzzerAktif,
    });

    if (mounted) {
      setState(() {
        isSaving = false;
      });

      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil disimpan'),
          ),
        );
      }
    }
  }

  void _changeTheme(ThemeMode mode) {
    setState(() {
      selectedThemeMode = mode;
    });

    MyApp.of(context)?.changeTheme(mode);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color pageBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB);

    final Color textColor =
        isDark ? const Color(0xFFF9FAFB) : AppTheme.darkText;

    final Color subTextColor = isDark ? Colors.white70 : AppTheme.greyText;

    return Scaffold(
      backgroundColor: pageBg,
      bottomNavigationBar: BottomNav(currentIndex: 3),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Pengaturan',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Atur perangkat, batas sensor, LCD, dan buzzer',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _SectionCard(
                    title: 'Perangkat',
                    children: [
                      _InputField(
                        controller: namaPerangkatController,
                        label: 'Nama Perangkat',
                        icon: Icons.devices_rounded,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nama perangkat ini akan tampil pada LCD I2C.',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _SectionCard(
                    title: 'Batas Suhu',
                    children: [
                      _InputField(
                        controller: batasSuhuWaspadaController,
                        label: 'Batas Suhu Waspada',
                        icon: Icons.thermostat_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: batasSuhuDaruratController,
                        label: 'Batas Suhu Darurat',
                        icon: Icons.thermostat_auto_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _SectionCard(
                    title: 'Batas Asap',
                    children: [
                      _InputField(
                        controller: batasAsapWaspadaController,
                        label: 'Batas Asap Waspada',
                        icon: Icons.cloud_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: batasAsapDaruratController,
                        label: 'Batas Asap Darurat',
                        icon: Icons.warning_amber_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _SectionCard(
                    title: 'Buzzer',
                    children: [
                      SwitchListTile(
                        value: buzzerAktif,
                        onChanged: (value) {
                          setState(() {
                            buzzerAktif = value;
                          });
                        },
                        title: const Text('Aktifkan Buzzer'),
                        subtitle: const Text(
                          'Buzzer akan berbunyi saat kondisi WASPADA atau DARURAT.',
                        ),
                        secondary: Icon(
                          buzzerAktif
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _SectionCard(
                    title: 'Tampilan',
                    children: [
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.system,
                        groupValue: selectedThemeMode,
                        onChanged: (value) {
                          if (value != null) _changeTheme(value);
                        },
                        title: const Text('Ikuti Sistem'),
                      ),
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.light,
                        groupValue: selectedThemeMode,
                        onChanged: (value) {
                          if (value != null) _changeTheme(value);
                        },
                        title: const Text('Mode Light'),
                      ),
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.dark,
                        groupValue: selectedThemeMode,
                        onChanged: (value) {
                          if (value != null) _changeTheme(value);
                        },
                        title: const Text('Mode Dark'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _saveSettings,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textColor =
        isDark ? const Color(0xFFF9FAFB) : AppTheme.darkText;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}