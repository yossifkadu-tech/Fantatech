// ─────────────────────────────────────────────────────────────────────────────
// FaceEnrollmentScreen — manage known persons + Azure Face API settings
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/app_state.dart';
import '../../models/known_person.dart';
import '../../theme/app_theme.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  bool _trainingInProgress = false;
  String? _statusMsg;

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final persons = state.knownPersons;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────
            _TopBar(
              onAdd: () => _showAddPersonSheet(context, state),
            ),

            // ── Azure settings ───────────────────────────────────
            _AzureSettingsCard(state: state),

            const SizedBox(height: 8),

            // ── Train button ─────────────────────────────────────
            if (state.hasAzureConfig && persons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _trainingInProgress ? null : () => _train(state),
                    icon: _trainingInProgress
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.model_training, size: 18),
                    label: Text(_trainingInProgress
                        ? 'מאמן מודל...'
                        : 'אמן מודל זיהוי (${persons.where((p) => p.isEnrolledInAzure).length}/${persons.length} רשומים)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B2FFF),
                      foregroundColor: context.tText,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

            if (_statusMsg != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.tText2(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_statusMsg!,
                      style: TextStyle(
                          color: context.tText2(0.7), fontSize: 12)),
                ),
              ),

            const SizedBox(height: 12),

            // ── Person list ──────────────────────────────────────
            Expanded(
              child: persons.isEmpty
                  ? _EmptyPersons(
                      onAdd: () => _showAddPersonSheet(context, state))
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: persons.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _PersonCard(
                        person: persons[i],
                        onDelete: () => _deletePerson(state, persons[i]),
                        onAddPhoto: () =>
                            _addPhotoToPerson(state, persons[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _train(AppState state) async {
    final svc = state.azureFaceService;
    if (svc == null) return;

    setState(() {
      _trainingInProgress = true;
      _statusMsg = 'מכין קבוצה...';
    });

    await svc.ensurePersonGroup();
    final started = await svc.trainPersonGroup();

    if (!started) {
      setState(() {
        _trainingInProgress = false;
        _statusMsg = '❌ לא ניתן להתחיל אימון';
      });
      return;
    }

    setState(() => _statusMsg = 'מאמן... (עשויה לקחת עד 60 שניות)');

    // Poll for completion
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final status = await svc.getTrainingStatus();
      if (status == 'succeeded') {
        setState(() {
          _trainingInProgress = false;
          _statusMsg = '✅ המודל אומן בהצלחה! הזיהוי פעיל.';
        });
        return;
      }
      if (status == 'failed') break;
    }

    setState(() {
      _trainingInProgress = false;
      _statusMsg = '❌ האימון נכשל. נסה שוב.';
    });
  }

  void _showAddPersonSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddPersonSheet(state: state),
    );
  }

  Future<void> _deletePerson(AppState state, KnownPerson person) async {
    // Delete from Azure if enrolled
    if (person.isEnrolledInAzure && person.azurePersonId != null) {
      final svc = state.azureFaceService;
      await svc?.deletePerson(person.azurePersonId!);
    }
    state.removeKnownPerson(person.id);
  }

  Future<void> _addPhotoToPerson(
      AppState state, KnownPerson person) async {
    final svc = state.azureFaceService;
    if (svc == null) {
      _showSnack('הגדר API Key של Azure תחילה');
      return;
    }

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 90);
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();

    setState(() => _statusMsg = 'מוסיף תמונה ל-Azure...');

    // Ensure person exists in Azure
    String? azurePersonId = person.azurePersonId;
    if (azurePersonId == null) {
      await svc.ensurePersonGroup();
      azurePersonId = await svc.createPerson(person.name);
      if (azurePersonId == null) {
        setState(() => _statusMsg = '❌ שגיאה ביצירת רשומה ב-Azure');
        return;
      }
    }

    final faceId = await svc.addFaceToPerson(azurePersonId, bytes);
    if (faceId == null) {
      setState(() => _statusMsg = '❌ לא ניתן לזהות פנים בתמונה זו');
      return;
    }

    final updated = KnownPerson(
      id:                 person.id,
      name:               person.name,
      azurePersonId:      azurePersonId,
      localImagePath:     xFile.path,
      enrolledAt:         person.enrolledAt,
      isEnrolledInAzure:  true,
    );
    state.updateKnownPerson(updated);
    setState(() => _statusMsg = '✅ תמונה נוספה ל-${person.name}. אמן את המודל.');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: context.tCard),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onAdd;
  const _TopBar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.chevron_right,
                  color: context.tText, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('זיהוי זהות',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('רשום אנשים מוכרים לזיהוי אוטומטי',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.person_add_outlined,
                  color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Azure settings card ───────────────────────────────────────────────────────

class _AzureSettingsCard extends StatefulWidget {
  final AppState state;
  const _AzureSettingsCard({required this.state});

  @override
  State<_AzureSettingsCard> createState() => _AzureSettingsCardState();
}

class _AzureSettingsCardState extends State<_AzureSettingsCard> {
  bool _expanded = false;
  bool _testing  = false;
  String? _testResult;

  late final _endpointCtrl = TextEditingController(
      text: widget.state.azureEndpoint ?? '');
  late final _keyCtrl = TextEditingController(
      text: widget.state.azureApiKey ?? '');

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasConfig = widget.state.hasAzureConfig;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasConfig
                ? const Color(0xFF00B4D8).withValues(alpha: 0.4)
                : context.tText2(0.10),
          ),
        ),
        child: Column(
          children: [
            // Header row
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0078D4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.cloud_outlined,
                          color: Color(0xFF0078D4), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Azure Face API',
                              style: TextStyle(
                                  color: context.tText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            hasConfig ? '✓ מוגדר' : 'לא מוגדר — לחץ להגדרה',
                            style: TextStyle(
                              color: hasConfig
                                  ? const Color(0xFF00C896)
                                  : context.tText2(0.38),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: context.tText2(0.38),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded settings
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: [
                    _AzureTF(
                      ctrl: _endpointCtrl,
                      label: 'Endpoint URL',
                      hint: 'https://your-resource.cognitiveservices.azure.com/',
                      icon: Icons.link,
                    ),
                    const SizedBox(height: 8),
                    _AzureTF(
                      ctrl: _keyCtrl,
                      label: 'API Key',
                      hint: '32-char hex key',
                      icon: Icons.key_outlined,
                      obscure: true,
                    ),
                    const SizedBox(height: 10),
                    if (_testResult != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _testResult!.startsWith('✅')
                              ? Colors.green.withValues(alpha: 0.10)
                              : Colors.red.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_testResult!,
                            style: TextStyle(
                                color: context.tText2(0.7), fontSize: 12)),
                      ),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _testing ? null : _test,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0078D4),
                            side: const BorderSide(
                                color: Color(0xFF0078D4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _testing
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0078D4)))
                              : Text('בדוק חיבור'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0078D4),
                            foregroundColor: context.tText,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('שמור'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'קבל API Key חינם בـ portal.azure.com → Cognitive Services',
                      style: TextStyle(
                          color: context.tText2(0.25),
                          fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _test() async {
    setState(() { _testing = true; _testResult = null; });
    final svc = widget.state.azureFaceService;
    if (svc == null) {
      // Use the current text fields
      final tempSvc = _endpointCtrl.text.trim().isNotEmpty &&
              _keyCtrl.text.trim().isNotEmpty
          ? null // will test after save
          : null;
      setState(() {
        _testing = false;
        _testResult = '⚠️ שמור את ההגדרות תחילה';
      });
      return;
    }
    final ok = await svc.testConnection();
    setState(() {
      _testing = false;
      _testResult = ok ? '✅ חיבור ל-Azure הצליח!' : '❌ לא ניתן להתחבר. בדוק Endpoint + Key';
    });
  }

  void _save() {
    widget.state.setAzureCredentials(
        _endpointCtrl.text.trim(), _keyCtrl.text.trim());
    setState(() {
      _expanded    = false;
      _testResult  = null;
    });
  }
}

class _AzureTF extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  const _AzureTF({
    required this.ctrl, required this.label,
    required this.hint,  required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: context.tText, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            TextStyle(color: context.tText2(0.45), fontSize: 12),
        hintStyle:
            TextStyle(color: context.tText2(0.20), fontSize: 11),
        prefixIcon: Icon(icon, color: context.tText2(0.38), size: 16),
        filled: true,
        fillColor: context.tText2(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: context.tText2(0.12))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: context.tText2(0.12))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: Color(0xFF0078D4), width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

// ── Person card ───────────────────────────────────────────────────────────────

class _PersonCard extends StatelessWidget {
  final KnownPerson person;
  final VoidCallback onDelete;
  final VoidCallback onAddPhoto;
  const _PersonCard({
    required this.person,
    required this.onDelete,
    required this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: person.isEnrolledInAzure
              ? const Color(0xFF00C896).withValues(alpha: 0.3)
              : context.tText2(0.08),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onAddPhoto,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: person.localImagePath != null
                  ? ClipOval(
                      child: Image.file(
                        File(person.localImagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.person_outline,
                      color: AppColors.primary, size: 26),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name,
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (person.isEnrolledInAzure
                              ? const Color(0xFF00C896)
                              : Colors.orange)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      person.isEnrolledInAzure
                          ? '✓ רשום ב-Azure'
                          : '⚠ לא רשום — הוסף תמונה',
                      style: TextStyle(
                        color: person.isEnrolledInAzure
                            ? const Color(0xFF00C896)
                            : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),

          // Add photo button
          GestureDetector(
            onTap: onAddPhoto,
            child: Container(
              width: 34, height: 34,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: context.tText2(0.05),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: context.tText2(0.12)),
              ),
              child: Icon(Icons.add_a_photo_outlined,
                  color: context.tText2(0.54), size: 16),
            ),
          ),

          // Delete button
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add person sheet ──────────────────────────────────────────────────────────

class _AddPersonSheet extends StatefulWidget {
  final AppState state;
  const _AddPersonSheet({required this.state});

  @override
  State<_AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends State<_AddPersonSheet> {
  final _nameCtrl = TextEditingController();
  bool _loading   = false;
  String? _msg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: context.tText2(0.24),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Row(children: [
            Icon(Icons.person_add_outlined,
                color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('הוסף אדם',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            style: TextStyle(color: context.tText),
            decoration: InputDecoration(
              labelText: 'שם מלא',
              hintText: 'לדוגמה: יוסי לוי',
              labelStyle: TextStyle(
                  color: context.tText2(0.45)),
              hintStyle: TextStyle(
                  color: context.tText2(0.25),
                  fontSize: 12),
              prefixIcon: Icon(Icons.badge_outlined,
                  color: context.tText2(0.38), size: 18),
              filled: true,
              fillColor: context.tText2(0.06),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: context.tText2(0.12))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: context.tText2(0.12))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5)),
            ),
          ),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_msg!,
                  style: TextStyle(
                      color: context.tText2(0.6), fontSize: 12)),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _add,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: context.tText,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('הוסף'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _msg = 'הכנס שם'); return; }

    setState(() { _loading = true; _msg = 'יוצר רשומה...'; });

    final person = KnownPerson(
      id:          const Uuid().v4(),
      name:        name,
      enrolledAt:  DateTime.now(),
    );

    // Try to create in Azure immediately if configured
    final svc = widget.state.azureFaceService;
    if (svc != null) {
      await svc.ensurePersonGroup();
      final azureId = await svc.createPerson(name);
      if (azureId != null) {
        person.azurePersonId = azureId;
        // Note: not marking isEnrolledInAzure yet — need a face photo first
      }
    }

    widget.state.addKnownPerson(person);
    if (mounted) Navigator.pop(context);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyPersons extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPersons({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.group_outlined,
                color: AppColors.primary, size: 38),
          ),
          const SizedBox(height: 16),
          Text('אין אנשים רשומים',
              style: TextStyle(
                  color: context.tText2(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'הוסף אנשים כדי שהמצלמות\nיזהו אותם בשם',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.tText2(0.3), fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.person_add_outlined, size: 16),
            label: Text('הוסף אדם'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: context.tText,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
