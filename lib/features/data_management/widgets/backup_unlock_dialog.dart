import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/l10n.dart';

/// Asks for the password of an encrypted backup; [wrong] after a password
/// that did not open it. The password, or `null` when cancelled.
Future<String?> showBackupUnlockDialog(
  BuildContext context, {
  bool wrong = false,
}) => showDialog<String>(
  context: context,
  builder: (_) => BackupUnlockDialog(wrong: wrong),
);

class BackupUnlockDialog extends HookWidget {
  const BackupUnlockDialog({super.key, this.wrong = false});

  final bool wrong;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final password = useTextEditingController();
    final hidden = useState(true);
    void open() {
      if (password.text.isNotEmpty) Navigator.pop(context, password.text);
    }

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.backupUnlockTitle),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(l10n.backupUnlockBody),
          TextField(
            controller: password,
            autofocus: true,
            obscureText: hidden.value,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.backupPassword,
              errorText: wrong ? l10n.backupUnlockWrong : null,
              suffixIcon: IconButton(
                tooltip: hidden.value ? l10n.passwordShow : l10n.passwordHide,
                icon: Icon(
                  hidden.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off,
                ),
                onPressed: () => hidden.value = !hidden.value,
              ),
            ),
            onSubmitted: (_) => open(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: open, child: Text(l10n.backupUnlockOpen)),
      ],
    );
  }
}
