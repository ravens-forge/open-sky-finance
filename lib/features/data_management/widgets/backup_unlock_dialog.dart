import 'package:flutter/material.dart';

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

class BackupUnlockDialog extends StatefulWidget {
  const BackupUnlockDialog({super.key, this.wrong = false});

  final bool wrong;

  @override
  State<BackupUnlockDialog> createState() => _BackupUnlockDialogState();
}

class _BackupUnlockDialogState extends State<BackupUnlockDialog> {
  final _password = TextEditingController();
  var _hidden = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _open() {
    if (_password.text.isNotEmpty) Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.backupUnlockTitle),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(l10n.backupUnlockBody),
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: _hidden,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.backupPassword,
              errorText: widget.wrong ? l10n.backupUnlockWrong : null,
              suffixIcon: IconButton(
                tooltip: _hidden ? l10n.passwordShow : l10n.passwordHide,
                icon: Icon(
                  _hidden ? Icons.visibility_outlined : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              ),
            ),
            onSubmitted: (_) => _open(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _open, child: Text(l10n.backupUnlockOpen)),
      ],
    );
  }
}
