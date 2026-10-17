import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/result.dart';
import '../../../core/widgets/field_error.dart';
import '../../../data/models/label.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/repository_data_error.dart';

Future<void> showLabelNameDialog(BuildContext context, {Label? label}) =>
    showDialog<void>(
      context: context,
      builder: (context) => _LabelNameDialog(label: label),
    );

class _LabelNameDialog extends HookConsumerWidget {
  const _LabelNameDialog({this.label});

  final Label? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final name = useTextEditingController(text: label?.name);
    final error = useState<String?>(null);
    final saving = useState(false);

    Future<void> save() async {
      saving.value = true;
      final result = await ref
          .read(labelsRepositoryProvider)
          .save(id: label?.id, name: name.text);
      if (!context.mounted) return;
      saving.value = false;
      switch (result) {
        case Ok():
          Navigator.pop(context);
        case Err(error: RepositoryDataError.invalidName):
          error.value = l10n.errorNameRequired;
        case Err(error: RepositoryDataError.duplicateName):
          error.value = l10n.errorNameTaken;
        case Err():
          error.value = l10n.errorSaveFailed;
      }
    }

    return AlertDialog(
      scrollable: true,
      title: Text(label == null ? l10n.labelsNew : l10n.labelsRename),
      content: TextField(
        controller: name,
        maxLength: 100,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.fieldName,
          error: error.value == null ? null : FieldError(error.value!),
          counterText: '',
        ),
        onChanged: (_) => error.value = null,
        onSubmitted: (_) => saving.value ? null : save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: saving.value ? null : save,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
