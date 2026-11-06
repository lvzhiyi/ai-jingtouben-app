import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/db/app_database.dart';
import '../data/device/device_id_store.dart';
import '../data/prompt/template_repository.dart';
import '../data/repositories/character_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/project_repository.dart';
import '../data/repositories/shot_repository.dart';
import '../data/storyboard/storyboard_api.dart';
import '../net/http_client.dart';

/// 统一持有长生命周期依赖。页面通过 RepositoryProvider 读取，不自己创建数据库或网络客户端。
class AppDependencies {
  AppDependencies._({
    required this.config,
    required this.database,
    required this.httpClient,
    required this.projects,
    required this.shots,
    required this.progress,
    required this.characters,
    required this.storyboard,
    required this.templates,
  });

  final AppConfig config;
  final AppDatabase database;
  final http.Client httpClient;
  final ProjectRepository projects;
  final ShotRepository shots;
  final ProgressRepository progress;
  final CharacterRepository characters;
  final StoryboardApi storyboard;
  final TemplateRepository templates;

  /// 读取构建配置、打开数据库并组装各仓库。[database]、[httpClient] 仅供测试注入。
  ///
  /// 中途失败会先释放已创建的资源再抛出；成功后由持有方调用 [close]。
  static Future<AppDependencies> initialize({
    AppDatabase? database,
    http.Client? httpClient,
  }) async {
    final config = AppConfig.fromEnvironment();
    final db = database ?? AppDatabase.open();
    final client = httpClient ?? createStreamingClient();
    try {
      // drift 懒打开数据库，先查一次，让打开失败暴露在启动阶段而不是第一个页面。
      await db.customSelect('SELECT 1').get();
      final deviceId = DeviceIdStore(db);
      return AppDependencies._(
        config: config,
        database: db,
        httpClient: client,
        projects: ProjectRepository(db),
        shots: ShotRepository(db),
        progress: ProgressRepository(db),
        characters: CharacterRepository(db),
        storyboard: StoryboardApi(
          client: client,
          baseUrl: config.apiBaseUrl,
          deviceId: deviceId.read,
        ),
        templates: TemplateRepository(client: client, baseUrl: config.apiBaseUrl, database: db),
      );
    } catch (_) {
      client.close();
      await db.close();
      rethrow;
    }
  }

  /// 先关网络客户端（中止进行中的流），再关数据库。
  Future<void> close() async {
    httpClient.close();
    await database.close();
  }
}
