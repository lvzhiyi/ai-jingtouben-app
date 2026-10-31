import 'package:go_router/go_router.dart';

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
        ),
      ],
    ),
  ],
);
