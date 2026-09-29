abstract final class Links {
  static const source = 'https://github.com/ravens-forge/open-sky-finance';
  static const license = '$source/blob/main/LICENSE';
  static const translate = '$source/blob/main/CONTRIBUTING.md#translations';

  /// The only donation link: the README section, so channels can change without a
  /// release.
  static const support = '$source#support-the-project';

  /// Issue forms.
  static const bugReport = '$source/issues/new?template=bug_report.yml';
  static const featureRequest =
      '$source/issues/new?template=feature_request.yml';

  /// The issue form at [form] ([bugReport] or [featureRequest]) with its
  /// inputs pre-filled: [fields] maps the form's field ids to their values.
  static Uri issueForm(String form, [Map<String, String> fields = const {}]) {
    final uri = Uri.parse(form);
    return uri.replace(queryParameters: {...uri.queryParameters, ...fields});
  }
}
