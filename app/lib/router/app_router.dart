import 'package:go_router/go_router.dart';

import '../pages/characters/page.dart';
import '../pages/preview/page.dart';
import '../pages/progress/page.dart';
import '../pages/projects/page.dart';
import '../pages/storyboard/page.dart';

/// 统一声明页面路由。第一版没有账号，不需要会话守卫。
GoRouter createRouter() => GoRouter(
  initialLocation: '/projects',
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/projects'),
    GoRoute(
      path: '/projects',
      builder: (_, _) => const ProjectsPage(),
      routes: [
        GoRoute(
          path: ':projectId',
          builder: (_, state) => StoryboardPage(projectId: state.pathParameters['projectId']!),
          routes: [
            GoRoute(
              path: 'characters',
              builder: (_, state) => CharactersPage(projectId: state.pathParameters['projectId']!),
            ),
            GoRoute(
              path: 'preview',
              builder: (_, state) => PreviewPage(
                projectId: state.pathParameters['projectId']!,
                startShot: int.tryParse(state.uri.queryParameters['shot'] ?? ''),
              ),
            ),
            GoRoute(
              path: 'progress',
              builder: (_, state) => ProgressPage(projectId: state.pathParameters['projectId']!),
            ),
          ],
        ),
      ],
    ),
  ],
);
