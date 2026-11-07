import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/prop_drawing_status.dart';
import '../../data/models/shot_duration.dart';
import '../../resources/theme.dart';
import 'controller.dart';
import 'preview_motion.dart';
import 'state.dart';
import 'widgets/playback_bar.dart';
import 'widgets/shot_frame.dart';

/// 镜头预演：9:16 示意画面按时长自动播放，底部是分段进度条和播放控制。
///
/// 镜头内进度由这里的 [AnimationController] 驱动：每帧只重绘画面、字幕和进度条，
/// 控制器只在换镜、暂停、播完时更新状态。
class PreviewView extends StatefulWidget {
  const PreviewView({super.key});

  @override
  State<PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<PreviewView> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) context.read<PreviewController>().next();
    });

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// 上次对齐时的 [PreviewState.cue]；变了才把镜头内进度归零，暂停 / 继续不归零。
  int _cue = -1;

  /// 状态变化后对齐计时：换镜时归零并换时长，再按是否在播决定走或停。
  void _sync(PreviewState state) {
    final shot = state.current;
    if (shot == null) return;
    if (state.cue != _cue) {
      _cue = state.cue;
      _clock.duration = Duration(milliseconds: shot.effectiveDurationMs);
      _clock.value = 0;
    }
    if (state.finished) {
      _clock.value = 1;
    } else if (state.playing) {
      _clock.forward();
    } else {
      _clock.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PreviewController, PreviewState>(
      listenWhen: (previous, current) =>
          previous.cue != current.cue ||
          previous.playing != current.playing ||
          previous.finished != current.finished,
      listener: (context, state) => _sync(state),
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('镜头预演'),
          actions: [
            IconButton(
              tooltip: state.showScene ? '隐藏画面描述' : '显示画面描述',
              isSelected: state.showScene,
              icon: const Icon(Icons.notes_rounded),
              onPressed: context.read<PreviewController>().toggleScene,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: switch (state) {
          PreviewState(loading: true) => const Center(child: CircularProgressIndicator()),
          PreviewState(shots: []) => const Center(child: Text('还没有镜头，先回分镜页生成')),
          _ => _PreviewBody(state: state, clock: _clock),
        },
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.state, required this.clock});

  final PreviewState state;
  final AnimationController clock;

  void _showProps(BuildContext context) {
    final controller = context.read<PreviewController>();
    final names = state.currentGeneratedProps;
    final messenger = ScaffoldMessenger.of(context);
    if (names.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('这个镜头没有可重画的道具')));
      return;
    }
    controller.pause();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppUi.pagePadding, 0, AppUi.pagePadding, 8),
              child: Text('本镜道具', style: Theme.of(sheetContext).textTheme.titleMedium),
            ),
            for (final name in names)
              ListTile(
                title: Text(name),
                subtitle: Text(switch (state.propRecords[name]?.status) {
                  PropDrawingStatus.ready => '已生成',
                  PropDrawingStatus.failed => '生成失败',
                  null => '生成中',
                }),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('正在重画「$name」')));
                    controller.redraw(name);
                  },
                  child: const Text('重画'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PreviewController>();
    final shot = state.current!;
    final theme = Theme.of(context);
    final propDrawings = state.propDrawings;
    return Column(
      children: [
        Expanded(
          child: ColoredBox(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                // 长按画面：暂停并列出本镜的生成道具，可以重画
                child: GestureDetector(
                  onLongPress: () => _showProps(context),
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: clock,
                      builder: (context, _) => ShotFrame(
                        shot: shot,
                        position: state.index + 1,
                        total: state.shots.length,
                        progress: clock.value,
                        showScene: state.showScene,
                        propDrawings: propDrawings,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppUi.contentMaxWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppUi.pagePadding, 8, AppUi.pagePadding, 12),
                child: AnimatedBuilder(
                  animation: clock,
                  builder: (context, _) {
                    final elapsed = state.finished
                        ? state.totalMs
                        : state.startMs + (clock.value * shot.effectiveDurationMs).round();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlaybackBar(
                          shots: state.shots,
                          index: state.index,
                          progress: state.finished ? 1 : clock.value,
                          onSeek: controller.seek,
                        ),
                        Row(
                          children: [
                            Text(
                              '${formatPlaybackTime(elapsed)} / ${formatPlaybackTime(state.totalMs)}',
                              style: theme.textTheme.labelMedium,
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: '上一镜',
                              icon: const Icon(Icons.skip_previous_rounded),
                              onPressed: controller.previous,
                            ),
                            IconButton.filled(
                              tooltip: state.finished ? '重播' : (state.playing ? '暂停' : '播放'),
                              iconSize: 32,
                              icon: Icon(
                                state.finished
                                    ? Icons.replay_rounded
                                    : (state.playing
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded),
                              ),
                              onPressed: state.finished ? controller.replay : controller.togglePlay,
                            ),
                            IconButton(
                              tooltip: '下一镜',
                              icon: const Icon(Icons.skip_next_rounded),
                              onPressed: state.finished ? null : controller.next,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
