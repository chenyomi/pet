import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pet_state.dart';
import '../services/app_lifecycle_manager.dart';
import '../services/floating_window_manager.dart';
import '../services/pet_save_repository.dart';
import '../widgets/pixel_pet.dart';

class PetHomeScreen extends StatefulWidget {
  const PetHomeScreen({super.key});

  @override
  State<PetHomeScreen> createState() => _PetHomeScreenState();
}

class _PetHomeScreenState extends State<PetHomeScreen> {
  late final PetEngine _engine;
  late final PetSaveRepository _repository;
  late final AppLifecycleManager _lifecycleManager;
  late PetSnapshot _state;
  late DateTime _now;
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _engine = PetEngine();
    _repository = PetSaveRepository();
    _lifecycleManager = AppLifecycleManager(petStateListener: (state) {});
    _now = DateTime.now();
    _state = PetSnapshot.initial(now: _now);
    _bootstrap();
    _timer = Timer.periodic(const Duration(seconds: 1), _handleTick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycleManager.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final loaded = await _repository.load();
    if (!mounted) return;
    final now = DateTime.now();
    final resolved = _engine.resolveTime(loaded, now);
    setState(() {
      _now = now;
      _state = resolved;
      _loading = false;
    });
    _lifecycleManager.updatePetState(resolved);
    unawaited(_repository.save(resolved));
  }

  void _handleTick(Timer timer) {
    if (_loading) return;
    final now = DateTime.now();
    final resolved = _engine.resolveTime(_state, now);
    setState(() {
      _now = now;
      _state = resolved;
    });
    _lifecycleManager.updatePetState(resolved);
    unawaited(_repository.save(resolved));
  }

  void _handleAction(PetAction action) {
    if (_loading) return;
    final now = DateTime.now();
    final updated = _engine.applyAction(_state, action, now);
    setState(() {
      _now = now;
      _state = updated;
    });
    _lifecycleManager.updatePetState(updated);
    unawaited(_repository.save(updated));
    _showToast(updated.logs.first);
  }

  Future<void> _openCodeDialog() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('输入秘码'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: '例如 HATCH-777',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );

    if (!mounted || code == null) return;

    final now = DateTime.now();
    final updated = _engine.applySecretCode(_state, code, now);
    setState(() {
      _now = now;
      _state = updated;
    });
    _lifecycleManager.updatePetState(updated);
    unawaited(_repository.save(updated));
    _showToast(updated.logs.first);
  }

  void _showToast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final outerCompact = MediaQuery.sizeOf(context).width < 720;
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final species = _engine.speciesOf(_state);
    final mood = _engine.moodOf(_state);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF4CF), Color(0xFFF5D97D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(outerCompact ? 12 : 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF6BB44),
                borderRadius: BorderRadius.circular(outerCompact ? 24 : 36),
                border: Border.all(color: const Color(0xFF20363A), width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x5C815309),
                    blurRadius: 30,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(outerCompact ? 12 : 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 980;
                    return Flex(
                      direction: compact ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: compact ? 0 : 11,
                          child: _PetDisplayPanel(
                            species: species,
                            mood: mood,
                            state: _state,
                            engine: _engine,
                            now: _now,
                          ),
                        ),
                        SizedBox(width: compact ? 0 : 20, height: compact ? 20 : 0),
                        Expanded(
                          flex: 10,
                          child: _ControlPanel(
                            state: _state,
                            species: species,
                            engine: _engine,
                            now: _now,
                            onAction: _handleAction,
                            onEnterCode: _openCodeDialog,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PetDisplayPanel extends StatelessWidget {
  const _PetDisplayPanel({
    required this.species,
    required this.mood,
    required this.state,
    required this.engine,
    required this.now,
  });

  final PetSpecies species;
  final PetMood mood;
  final PetSnapshot state;
  final PetEngine engine;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopBar(),
            const SizedBox(height: 16),
            Container(
              height: compact ? 300 : 420,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF8FD4DB),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF20363A), width: 4),
                gradient: const LinearGradient(
                  colors: [Color(0xFFA7E7EF), Color(0xFF72BECA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridPainter(),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    top: 18,
                    child: _FxBadge(text: _topText()),
                  ),
                  if (species.secret)
                    const Positioned(
                      right: 18,
                      top: 18,
                      child: _FxBadge(text: 'SECRET'),
                    ),
                  Center(
                    child: AnimatedScale(
                      scale: mood == PetMood.battle ? 1.06 : 1,
                      duration: const Duration(milliseconds: 220),
                      child: PixelPet(
                        species: species,
                        mood: mood,
                        size: compact ? 196 : 264,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    bottom: 18,
                    child: _FxBadge(text: _bottomText()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ScreenTag(label: '阶段', value: '${species.name} / ${PetEngine.stageNames[species.stage]}'),
                _ScreenTag(label: '年龄', value: '${state.age}'),
                _ScreenTag(label: '状态', value: _statusText()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusText() {
    if (!state.alive) return '已离开';
    if (state.sleeping) return '休息中';
    if (state.sick) return '生病';
    return species.line;
  }

  String _topText() {
    if (!state.alive) return '...';
    if (species.stage == PetStage.egg) {
      final remain = engine.hatchRemaining(state, now);
      if (remain == null || remain == Duration.zero) return 'READY';
      return '孵化 ${PetEngine.formatDuration(remain)}';
    }
    if (state.sleeping) return 'Zzz';
    if (state.sick) return '!';
    if (state.hunger < 30) return '咕';
    return '';
  }

  String _bottomText() {
    if (!state.alive) return 'GAME OVER';
    if (state.poop >= 2) return '要清洁';
    if (state.eventText != '平静') return state.eventText;
    return '';
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.state,
    required this.species,
    required this.engine,
    required this.now,
    required this.onAction,
    required this.onEnterCode,
  });

  final PetSnapshot state;
  final PetSpecies species;
  final PetEngine engine;
  final DateTime now;
  final ValueChanged<PetAction> onAction;
  final Future<void> Function() onEnterCode;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final rules = {
      for (final action in PetAction.values) action: engine.actionRule(state, action, now),
    };

    final hatchRemain = engine.hatchRemaining(state, now);
    final exploreRemain = engine.exploreRefillRemaining(state, now);
    final battleRemain = engine.battleRefillRemaining(state, now);

    return Card(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? double.infinity : 520,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '数码宠物机',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF20363A),
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '这版已经把“不能无限点”的规则锁起来了。孵化要等真实倒计时，探索和战斗要恢复次数，重启也要先拿到权限秘码。',
                        style: TextStyle(
                          height: 1.5,
                          color: Color(0xFF304B51),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onEnterCode,
                  icon: const Icon(Icons.password_rounded),
                  label: const Text('输入秘码'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9EA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF20363A), width: 3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '后台悬浮窗',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '游戏运行时悬浮窗已隐藏。当你退出游戏后，可爱的宠物会在屏幕上浮动显示，继续陪伴你。',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _StatGrid(state: state),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetaCard(title: '图鉴', value: '${state.discovered.length}/${PetEngine.speciesPool.length}'),
                _MetaCard(title: '分支', value: species.line),
                _MetaCard(title: '事件', value: state.eventText),
                _MetaCard(title: '胜场', value: '${state.wins}'),
                _MetaCard(title: '便便', value: '${state.poop}'),
                _MetaCard(title: '失误', value: '${state.careMistakes}'),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '规则面板',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _RuleCard(
                  title: '孵化倒计时',
                  value: hatchRemain == null
                      ? '已完成'
                      : hatchRemain == Duration.zero
                          ? '可孵化'
                          : PetEngine.formatDuration(hatchRemain),
                  hint: species.stage == PetStage.egg ? '到点后随机破壳' : '这一轮已经结束',
                ),
                _RuleCard(
                  title: '探索充能',
                  value: '${state.exploreCharges}/${PetEngine.maxExploreCharges}',
                  hint: exploreRemain == null ? '已充满' : '下次恢复 ${PetEngine.formatDuration(exploreRemain)}',
                ),
                _RuleCard(
                  title: '战斗门票',
                  value: '${state.battleCharges}/${PetEngine.maxBattleCharges}',
                  hint: battleRemain == null ? '已充满' : '下次恢复 ${PetEngine.formatDuration(battleRemain)}',
                ),
                _RuleCard(
                  title: '重启权限',
                  value: state.restartUnlocked ? '已解锁' : '锁定',
                  hint: state.restartUnlocked ? '可以使用一次重启舱' : '输入 RESET-KEY 才能用',
                ),
                _RuleCard(
                  title: '秘码状态',
                  value: '${state.usedCodes.length} 个',
                  hint: state.forcedNextSpeciesId != null ? '隐藏胚体待孵化' : '输入后可打破规则',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '行动',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionChip(label: '孵化', action: PetAction.hatch, onAction: onAction, rule: rules[PetAction.hatch]!),
                _ActionChip(label: '喂食', action: PetAction.feed, onAction: onAction, rule: rules[PetAction.feed]!),
                _ActionChip(label: '训练', action: PetAction.train, onAction: onAction, rule: rules[PetAction.train]!),
                _ActionChip(label: '探索', action: PetAction.explore, onAction: onAction, rule: rules[PetAction.explore]!),
                _ActionChip(label: '清洁', action: PetAction.clean, onAction: onAction, rule: rules[PetAction.clean]!),
                _ActionChip(label: '休息', action: PetAction.rest, onAction: onAction, rule: rules[PetAction.rest]!),
                _ActionChip(label: '战斗', action: PetAction.battle, onAction: onAction, rule: rules[PetAction.battle]!),
                _ActionChip(label: '表扬', action: PetAction.praise, onAction: onAction, rule: rules[PetAction.praise]!),
                _ActionChip(label: '治疗', action: PetAction.medicine, onAction: onAction, rule: rules[PetAction.medicine]!),
                _ActionChip(
                  label: '重启舱',
                  action: PetAction.restart,
                  onAction: onAction,
                  rule: rules[PetAction.restart]!,
                  danger: true,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9EA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF20363A), width: 3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '成长记录',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      itemCount: state.logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return Text(
                          '• ${state.logs[index]}',
                          style: const TextStyle(height: 1.5),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '当前内置秘码示例：HATCH-777、PROTO-MON、OVERCLOCK、RESET-KEY。',
              style: TextStyle(
                color: Color(0xFF304B51),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.state});

  final PetSnapshot state;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('饥饿', state.hunger),
      ('心情', state.moodValue),
      ('体力', state.energy),
      ('卫生', state.cleanliness),
      ('纪律', state.discipline),
      ('战力', state.power),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => SizedBox(
              width: 180,
              child: _StatCard(label: item.$1, value: item.$2),
            ),
          )
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final danger = value < 35;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF20363A), width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 12,
              backgroundColor: const Color(0xFFE5DCC0),
              color: danger ? const Color(0xFFC85343) : const Color(0xFF51A774),
            ),
          ),
          const SizedBox(height: 6),
          Text('${value.round()} / 100'),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.action,
    required this.onAction,
    required this.rule,
    this.danger = false,
  });

  final String label;
  final PetAction action;
  final ValueChanged<PetAction> onAction;
  final PetActionRule rule;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: FilledButton(
        onPressed: rule.enabled ? () => onAction(action) : null,
        style: FilledButton.styleFrom(
          backgroundColor: danger ? const Color(0xFFC85343) : const Color(0xFFEEF7FA),
          disabledBackgroundColor: const Color(0xFFD7D7D7),
          foregroundColor: danger ? Colors.white : const Color(0xFF20363A),
          disabledForegroundColor: const Color(0xFF6E6E6E),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF20363A), width: 2),
          ),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              rule.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF20363A), width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.title,
    required this.value,
    required this.hint,
  });

  final String title;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF20363A), width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: const TextStyle(fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _MacDot(color: Color(0xFFFF6B5F)),
        SizedBox(width: 8),
        _MacDot(color: Color(0xFFFEC84D)),
        SizedBox(width: 8),
        _MacDot(color: Color(0xFF2ACA44)),
        Spacer(),
        Text(
          'DIGI PET DESKTOP',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _MacDot extends StatelessWidget {
  const _MacDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: const Color(0xFF20363A), width: 1.5),
      ),
    );
  }
}

class _ScreenTag extends StatelessWidget {
  const _ScreenTag({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF20363A), width: 3),
      ),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w700),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _FxBadge extends StatelessWidget {
  const _FxBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF20363A), width: 2),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const lineColor = Color(0x33FFFFFF);
    const step = 18.0;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingPetPreview extends StatelessWidget {
  const _FloatingPetPreview({
    required this.species,
    required this.mood,
    required this.eventText,
  });

  final PetSpecies species;
  final PetMood mood;
  final String eventText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF20363A), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29172614),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelPet(species: species, mood: mood, size: 52),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  species.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  eventText,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
