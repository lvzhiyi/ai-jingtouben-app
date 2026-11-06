import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/shot_repository.dart';
import 'controller.dart';
import 'view.dart';

/// 镜头预演入口：在生成视频之前，用示意画面看一遍整份分镜的构图、运镜和节奏。
class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key, required this.projectId, this.startShot});

  final String projectId;

  /// 从哪个镜头开始（镜头序号）；为空时从第一镜开始。
  final int? startShot;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => PreviewController(
      projectId: projectId,
      shots: context.read<ShotRepository>(),
      startShot: startShot,
    )..load(),
    child: const PreviewView(),
  );
}
