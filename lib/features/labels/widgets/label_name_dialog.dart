import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../data/models/label.dart';
import '../../../data/repositories/repository_data_error.dart';
import '../providers/labels_controller.dart';

Future<void> showLabelNameDialog(BuildContext context, {Label? label}) =>
    showDialog<void>(
      context: context,
      builder: (context) => _LabelNameDialog(label: label),
    );

class _LabelNameDialog extends ConsumerStatefulWidget {
  const _LabelNameDialog({this.label});

  final Label? label;

  @override
  ConsumerState<_LabelNameDialog> createState() => _LabelNameDialogState();
}

class _LabelNameDialogState extends ConsumerState<_LabelNameDialog> {
  late final _name = TextEditingController(text: widget.label?.name);
  String? _error;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    final result = await ref
        .read(labelsControllerProvider.notifier)
        .save(id: widget.label?.id, name: _name.text);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        Navigator.pop(context);
      case Err(error: RepositoryDataError.invalidName):
        setState(() => _error = l10n.errorNameRequired);
      case Err(error: RepositoryDataError.duplicateName):
        setState(() => _error = l10n.errorNameTaken);
      case Err():
        setState(() => _error = l10n.errorSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      scrollable: true,
      title: Text(widget.label == null ? l10n.labelsNew : l10n.labelsRename),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: 100,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.fieldName,
          errorText: _error,
          counterText: '',
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _saving ? null : _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
