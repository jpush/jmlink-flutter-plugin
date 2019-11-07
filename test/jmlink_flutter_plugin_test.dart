import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmlink_flutter_plugin/jmlink_flutter_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('jmlink_flutter_plugin');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });


}
