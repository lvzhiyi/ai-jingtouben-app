import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

/// 安装级随机 ID，只用于转发服务按设备限流。
///
/// 不读取任何硬件标识，卸载重装即重置。它可以被伪造，所以服务端还要有 IP 维度的兜底。
class DeviceIdStore {
  DeviceIdStore(this._database, {this._uuid = const Uuid()});

  static const _key = 'device_id';

  final AppDatabase _database;
  final Uuid _uuid;
  Future<String>? _pending;

  /// 并发调用共享同一次读取；读取失败时清掉缓存，下次重试。
  Future<String> read() =>
      _pending ??= _readOrCreate().catchError((Object error, StackTrace stack) {
        _pending = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<String> _readOrCreate() async {
    final existing = await _database.readValue(_key);
    if (existing != null) return existing;
    final id = _uuid.v4();
    await _database.writeValue(_key, id);
    return id;
  }
}
