import 'package:integration_test/integration_test_driver.dart';

/// 把 integration_test 里 `watchPerformance` 收集的帧耗时写到 `build/storyboard_perf.json`。
Future<void> main() => integrationDriver(
  responseDataCallback: (data) =>
      writeResponseData(data, testOutputFilename: 'storyboard_perf', destinationDirectory: 'build'),
);
