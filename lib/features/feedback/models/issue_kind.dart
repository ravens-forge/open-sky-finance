import '../../../core/links.dart';

enum IssueKind {
  bug(Links.bugReport),
  idea(Links.featureRequest);

  const IssueKind(this.form);

  final String form;
}
