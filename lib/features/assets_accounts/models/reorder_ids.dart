/// [all] after moving the item of [group] at [from] to [to] (indexes within
/// [group], [to] counted after removing it). Ids outside [group], such as
/// hidden or other-type assets accounts, keep their place.
List<String> reorderIds(
  List<String> all,
  List<String> group,
  int from,
  int to,
) {
  final moved = [...group];
  moved.insert(to, moved.removeAt(from));
  final inGroup = group.toSet();
  final next = moved.iterator;
  return [
    for (final id in all)
      if (inGroup.contains(id)) (next..moveNext()).current else id,
  ];
}
