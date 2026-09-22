import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dates/year_month.dart';
import '../../../data/models/label_total.dart';
import '../../../data/providers.dart';

part 'labels_providers.g.dart';

@riverpod
Stream<List<LabelTotal>> labelTotals(Ref ref, YearMonth month) =>
    ref.watch(labelsRepositoryProvider).watchTotals(month.start, month.end);
