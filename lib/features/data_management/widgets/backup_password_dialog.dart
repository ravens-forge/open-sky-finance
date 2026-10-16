import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/l10n.dart';

/// Asks for a new backup password twice; the password, or `null` when
/// cancelled.
Future<String?> showBackupPasswordDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const BackupPasswordDialog(),
    );

class BackupPasswordDialog extends HookWidget {
  const BackupPasswordDialog({super.key});

  /// Shorter passwords are refused.
  static const minLength = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final form = useMemoized(GlobalKey<FormState>.new);
    final password = useTextEditingController();
    final hidden = useState(true);
    void save() {
      if (form.currentState!.validate()) Navigator.pop(context, password.text);
    }

    final toggle = IconButton(
      tooltip: hidden.value ? l10n.passwordShow : l10n.passwordHide,
      icon: Icon(
        hidden.value ? Icons.visibility_outlined : Icons.visibility_off,
      ),
      onPressed: () => hidden.value = !hidden.value,
    );
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.backupPasswordTitle),
      content: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(l10n.backupPasswordBody),
            TextFormField(
              controller: password,
              autofocus: true,
              obscureText: hidden.value,
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
              obscureText: hidden.value,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(labelText: l10n.backupPasswordRepeat),
              validator: (v) =>
                  v != password.text ? l10n.backupPasswordMismatch : null,
              onFieldSubmitted: (_) => save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: save, child: Text(l10n.backupPasswordSave)),
      ],
    );
  }
}
