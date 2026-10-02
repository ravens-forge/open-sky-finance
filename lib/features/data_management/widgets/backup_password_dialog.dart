import 'package:flutter/material.dart';

import '../../../core/l10n.dart';

/// Asks for a new backup password twice; the password, or `null` when
/// cancelled.
Future<String?> showBackupPasswordDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const BackupPasswordDialog(),
    );

class BackupPasswordDialog extends StatefulWidget {
  const BackupPasswordDialog({super.key});

  /// Shorter passwords are refused.
  static const minLength = 8;

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  var _hidden = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _save() {
    if (_form.currentState!.validate()) Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final toggle = IconButton(
      tooltip: _hidden ? l10n.passwordShow : l10n.passwordHide,
      icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off),
      onPressed: () => setState(() => _hidden = !_hidden),
    );
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.backupPasswordTitle),
      content: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(l10n.backupPasswordBody),
            TextFormField(
              controller: _password,
              autofocus: true,
              obscureText: _hidden,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.backupPassword,
                helperText: l10n.backupPasswordRule(
                  BackupPasswordDialog.minLength,
                ),
                suffixIcon: toggle,
              ),
              validator: (v) =>
                  (v ?? '').length < BackupPasswordDialog.minLength
                  ? l10n.backupPasswordTooShort(BackupPasswordDialog.minLength)
                  : null,
            ),
            TextFormField(
              obscureText: _hidden,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(labelText: l10n.backupPasswordRepeat),
              validator: (v) =>
                  v != _password.text ? l10n.backupPasswordMismatch : null,
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.backupPasswordSave)),
      ],
    );
  }
}
