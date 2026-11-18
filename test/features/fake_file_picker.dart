import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart' show XFile;

/// A picked file held in memory.
final class FakePickedFile extends PlatformFile {
  FakePickedFile(this.name, this.bytes);

  @override
  final String name;
  final Uint8List bytes;

  @override
  Uri get uri => Uri(scheme: 'memory', path: name);

  @override
  XFile get xFile => XFile.fromData(bytes, name: name);

  @override
  int? lengthSync() => bytes.length;

  @override
  Future<int?> length() async => bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

/// The system open and save dialogs: each open dialog returns the next of
/// [picks] (cancelled when none is left), and a save dialog writes to
/// [saved] unless [cancelSave].
class FakeFilePicker extends FilePickerPlatform {
  final picks = <FakePickedFile>[];
  final saved = <String, Uint8List>{};
  var cancelSave = false;

  /// Save dialogs shown so far, cancelled ones included.
  var saveDialogs = 0;

  /// Replaces the platform dialogs until the test ends.
  static FakeFilePicker install() {
    final before = FilePickerPlatform.instance;
    addTearDown(() => FilePickerPlatform.instance = before);
    final fake = FakeFilePicker();
    FilePickerPlatform.instance = fake;
    return fake;
  }

  void pick(String name, List<int> bytes) =>
      picks.add(FakePickedFile(name, Uint8List.fromList(bytes)));

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => picks.isEmpty ? null : picks.removeAt(0);

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    saveDialogs++;
    if (cancelSave) return null;
    saved[fileName] = bytes;
    return Uri(scheme: 'memory', path: fileName);
  }
}
