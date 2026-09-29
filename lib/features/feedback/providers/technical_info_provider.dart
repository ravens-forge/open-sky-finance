import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/providers.dart';
import '../models/technical_info.dart';

part 'technical_info_provider.g.dart';

/// Platform and OS version, e.g. `Android 15` or `iOS 18.4`.
@Riverpod(keepAlive: true)
Future<String> osVersion(Ref ref) async {
  final device = DeviceInfoPlugin();
  return switch (defaultTargetPlatform) {
    TargetPlatform.android =>
      'Android ${(await device.androidInfo).version.release}',
    TargetPlatform.iOS => 'iOS ${(await device.iosInfo).systemVersion}',
    _ => '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
  };
}

/// The technical info of a bug report, with the app in [language].
@riverpod
Future<TechnicalInfo> technicalInfo(Ref ref, String language) async {
  final package = await PackageInfo.fromPlatform();
  return TechnicalInfo(
    version: package.version,
    build: package.buildNumber,
    platform: await ref.watch(osVersionProvider.future),
    language: language,
    schemaVersion: ref.watch(appDatabaseProvider).schemaVersion,
  );
}
