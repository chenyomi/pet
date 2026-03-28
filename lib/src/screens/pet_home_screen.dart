import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/pet_state.dart';
import '../services/app_lifecycle_manager.dart';
import '../services/pet_save_repository.dart';
import '../widgets/pixel_pet.dart';

const _defaultBackgroundId = 'meadow_day';

enum _BackdropPattern {
  dots,
  sunsetLines,
  cyberGrid,
  mountain,
  waves,
  runes,
}

class _GameBackground {
  const _GameBackground({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.unlockHint,
    required this.icon,
    required this.gradient,
    required this.pattern,
    required this.patternColor,
    required this.glowColor,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final String unlockHint;
  final IconData icon;
  final List<Color> gradient;
  final _BackdropPattern pattern;
  final Color patternColor;
  final Color glowColor;
}

const _backgroundCatalog = <_GameBackground>[
  _GameBackground(
    id: 'meadow_day',
    name: '晴空草甸',
    tagline: '初始背景',
    description: '清晨的草甸被阳光照亮，适合新生的数码蛋慢慢成长。',
    unlockHint: '默认解锁',
    icon: Icons.park_rounded,
    gradient: [Color(0xFFA7E7EF), Color(0xFF72BECA)],
    pattern: _BackdropPattern.dots,
    patternColor: Color(0x3DFFFFFF),
    glowColor: Color(0x66F4FF9A),
  ),
  _GameBackground(
    id: 'sunset_camp',
    name: '余晖营地',
    tagline: '战斗入门',
    description: '日落时分的训练营，篝火边总能听到胜利后的欢呼。',
    unlockHint: '累计 3 场胜利',
    icon: Icons.wb_twilight_rounded,
    gradient: [Color(0xFFFFD089), Color(0xFFFF8C6A)],
    pattern: _BackdropPattern.sunsetLines,
    patternColor: Color(0x2EFFF6D6),
    glowColor: Color(0x66FFB25F),
  ),
  _GameBackground(
    id: 'cyber_grid',
    name: '霓虹矩阵',
    tagline: '图鉴探索',
    description: '城市中枢的虚拟演算场，适合观察不同族群的行为。',
    unlockHint: '图鉴达到 12 种',
    icon: Icons.grid_4x4_rounded,
    gradient: [Color(0xFF0E1F3F), Color(0xFF1A5F8A)],
    pattern: _BackdropPattern.cyberGrid,
    patternColor: Color(0x5A56E6FF),
    glowColor: Color(0x6626C6FF),
  ),
  _GameBackground(
    id: 'cloud_summit',
    name: '云巅神殿',
    tagline: '进化里程碑',
    description: '只有完成关键进化的灵兽才能踏上的高空神殿，圣轮与风纹终日回响。',
    unlockHint: '宠物达到成熟期',
    icon: Icons.terrain_rounded,
    gradient: [Color(0xFFC6D6FF), Color(0xFF7FA1E5)],
    pattern: _BackdropPattern.mountain,
    patternColor: Color(0x35FFFFFF),
    glowColor: Color(0x66D8E6FF),
  ),
  _GameBackground(
    id: 'deep_ruins',
    name: '深海遗迹',
    tagline: '高阶挑战',
    description: '沉在海底的古代遗迹，只有足够强的个体才能稳定探索。',
    unlockHint: '战力 ≥ 80 且胜场 ≥ 8',
    icon: Icons.waves_rounded,
    gradient: [Color(0xFF123A58), Color(0xFF0F5E73)],
    pattern: _BackdropPattern.waves,
    patternColor: Color(0x4FA9F6FF),
    glowColor: Color(0x6648D1FF),
  ),
  _GameBackground(
    id: 'paradox_archive',
    name: '悖论档案室',
    tagline: '隐藏成就',
    description: '封存禁忌数据的机密档案室，传说只为真正的探索者开启。',
    unlockHint: '发现任意隐藏系宠物并解锁重启权限',
    icon: Icons.auto_awesome_rounded,
    gradient: [Color(0xFF1A2038), Color(0xFF3A2D54)],
    pattern: _BackdropPattern.runes,
    patternColor: Color(0x4FB9A6FF),
    glowColor: Color(0x669D8BFF),
  ),
];

final Map<String, _GameBackground> _backgroundByIdMap = {
  for (final bg in _backgroundCatalog) bg.id: bg,
};

// ─── Screen ───────────────────────────────────────────────────────────────────

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
  double _topHudHeight = 56;

  _GameBackground _backgroundOf(String id) => _backgroundByIdMap[id] ?? _backgroundByIdMap[_defaultBackgroundId]!;

  bool _isBackgroundUnlockedByRule(_GameBackground bg, PetSnapshot state, PetSpecies species) {
    switch (bg.id) {
      case 'meadow_day':
        return true;
      case 'sunset_camp':
        return state.wins >= 3;
      case 'cyber_grid':
        return state.discovered.length >= 12;
      case 'cloud_summit':
        return species.stage.index >= PetStage.champion.index;
      case 'deep_ruins':
        return state.power >= 80 && state.wins >= 8;
      case 'paradox_archive':
        final secretIds = PetEngine.speciesPool.where((s) => s.secret).map((s) => s.id).toSet();
        final unlockedSecret = state.discovered.any(secretIds.contains);
        return unlockedSecret && state.restartUnlocked;
      default:
        return false;
    }
  }

  PetSnapshot _syncBackgroundUnlocks(
    PetSnapshot source, {
    bool notify = false,
  }) {
    final species = _engine.speciesOf(source);
    final unlocked = <String>{...source.unlockedBackgroundIds, _defaultBackgroundId};
    final newlyUnlocked = <_GameBackground>[];

    for (final bg in _backgroundCatalog) {
      if (unlocked.contains(bg.id)) continue;
      if (_isBackgroundUnlockedByRule(bg, source, species)) {
        unlocked.add(bg.id);
        newlyUnlocked.add(bg);
      }
    }

    final normalizedActive = unlocked.contains(source.activeBackgroundId)
        ? source.activeBackgroundId
        : _defaultBackgroundId;
    final unlockedChanged = unlocked.length != source.unlockedBackgroundIds.length;
    final activeChanged = normalizedActive != source.activeBackgroundId;
    var next = source;
    if (unlockedChanged || activeChanged) {
      next = source.copyWith(
        unlockedBackgroundIds: unlocked.toList(),
        activeBackgroundId: normalizedActive,
      );
    }

    if (newlyUnlocked.isEmpty) return next;

    final unlockLogs = [for (final bg in newlyUnlocked) '背景解锁：${bg.name}'];
    next = next.copyWith(
      eventText: '解锁新背景',
      logs: [...unlockLogs, ...next.logs].take(20).toList(),
    );
    if (notify && mounted) {
      _showToast(unlockLogs.first);
    }
    return next;
  }

  Future<void> _openBackgroundGallery() async {
    final synced = _syncBackgroundUnlocks(_state);
    if (synced != _state) {
      setState(() {
        _state = synced;
      });
      _lifecycleManager.updatePetState(synced);
      unawaited(_repository.save(synced));
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final species = _engine.speciesOf(_state);
        final width = MediaQuery.sizeOf(ctx).width;
        final crossAxisCount = width > 980 ? 3 : width > 680 ? 2 : 1;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 980, maxHeight: 720),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '背景图鉴',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF7FA),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF20363A), width: 1.2),
                      ),
                      child: Text(
                        '${_state.unlockedBackgroundIds.length}/${_backgroundCatalog.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20363A),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '突破条件即可永久解锁背景。已解锁背景可随时切换。',
                  style: TextStyle(fontSize: 13, color: Color(0xFF5A4A2A)),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    itemCount: _backgroundCatalog.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.24,
                    ),
                    itemBuilder: (context, i) {
                      final bg = _backgroundCatalog[i];
                      final unlocked = _state.unlockedBackgroundIds.contains(bg.id) ||
                          _isBackgroundUnlockedByRule(bg, _state, species);
                      final active = bg.id == _state.activeBackgroundId;
                      return _BackgroundDexCard(
                        background: bg,
                        unlocked: unlocked,
                        active: active,
                        onTap: unlocked
                            ? () {
                                Navigator.of(ctx).pop();
                                _activateBackground(bg);
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _activateBackground(_GameBackground bg) {
    final synced = _syncBackgroundUnlocks(_state);
    if (!synced.unlockedBackgroundIds.contains(bg.id)) return;
    final updated = synced.copyWith(
      activeBackgroundId: bg.id,
      eventText: '切换背景',
      logs: ['已切换背景：${bg.name}', ...synced.logs].take(20).toList(),
    );
    setState(() {
      _state = updated;
    });
    _lifecycleManager.updatePetState(updated);
    unawaited(_repository.save(updated));
    _showToast('已启用背景：${bg.name}');
  }

  Future<void> _openDexDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final width = MediaQuery.sizeOf(ctx).width;
        final crossAxisCount = width > 1100 ? 4 : width > 860 ? 3 : width > 620 ? 2 : 1;
        const speciesList = PetEngine.speciesPool;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 760),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '宠物图鉴',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF7FA),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF20363A), width: 1.2),
                      ),
                      child: Text(
                        '${_state.discovered.length}/${speciesList.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20363A),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '图鉴按新的世界观收录全部形态。每张卡片会显示下一阶段的主要演化去向，用来观察各分支的轮廓遗传。',
                  style: TextStyle(fontSize: 13, color: Color(0xFF5A4A2A)),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    itemCount: speciesList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, i) {
                      final pet = speciesList[i];
                      final unlocked = _state.discovered.contains(pet.id);
                      return _DexPetCard(
                        species: pet,
                        unlocked: unlocked,
                        evolvesTo: _evolutionTargets(pet),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PetSpecies> _evolutionTargets(PetSpecies species) {
    if (species.stage == PetStage.egg) {
      return PetEngine.speciesPool.where((s) => s.stage == PetStage.baby).toList();
    }
    if (species.stage == PetStage.baby) {
      return PetEngine.speciesPool.where((s) => s.stage == PetStage.rookie).toList();
    }
    if (species.stage == PetStage.rookie) {
      return PetEngine.speciesPool.where((s) => s.stage == PetStage.champion).toList();
    }
    if (species.stage == PetStage.champion) {
      return PetEngine.speciesPool.where((s) => s.stage == PetStage.ultimate).toList();
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _engine = PetEngine();
    _repository = PetSaveRepository();
    _lifecycleManager = AppLifecycleManager(petStateListener: (state) {});
    _now = DateTime.now();
    _state = PetSnapshot.initial(now: _now);
    _bootstrap();
    _timer = Timer.periodic(const Duration(seconds: 5), _handleTick);
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
    final resolved = _syncBackgroundUnlocks(_engine.resolveTime(loaded, now));
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
    final resolved = _syncBackgroundUnlocks(_engine.resolveTime(_state, now), notify: true);
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
    final updated = _syncBackgroundUnlocks(_engine.applyAction(_state, action, now));
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
      builder: (context) => AlertDialog(
        title: const Text('输入秘码'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: '例如 HATCH-777',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v),
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
      ),
    );
    if (!mounted || code == null) return;
    final now = DateTime.now();
    final updated = _syncBackgroundUnlocks(_engine.applySecretCode(_state, code, now));
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
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  void _openLogDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '成长记录',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _state.logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Color(0xFF7A6A40))),
                      Expanded(
                        child: Text(
                          _state.logs[i],
                          style: const TextStyle(height: 1.5, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openControlSheet() async {
    final species = _engine.speciesOf(_state);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final size = MediaQuery.sizeOf(sheetContext);
        final insets = MediaQuery.viewInsetsOf(sheetContext);
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + insets.bottom),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 980,
                  maxHeight: size.height * 0.86,
                ),
                child: _ControlPanel(
                  state: _state,
                  species: species,
                  engine: _engine,
                  now: _now,
                  onAction: (action) {
                    Navigator.of(sheetContext).pop();
                    _handleAction(action);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final species = _engine.speciesOf(_state);
    final mood = _engine.moodOf(_state);
    final background = _backgroundOf(_state.activeBackgroundId);
    final compact = MediaQuery.sizeOf(context).width < 720;
    final edgePadding = compact ? 10.0 : 14.0;
    final dockBottom = compact ? 58.0 : 64.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _PetDisplayPanel(
              species: species,
              mood: mood,
              state: _state,
              engine: _engine,
              now: _now,
              background: background,
              topOverlayReserve:
                  MediaQuery.paddingOf(context).top + edgePadding + _topHudHeight + 10,
              showTopBar: false,
              immersive: true,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  left: edgePadding,
                  right: edgePadding,
                  top: edgePadding,
                  child: _MeasureSize(
                    onChange: (size) {
                      if (!mounted) return;
                      if ((size.height - _topHudHeight).abs() < 0.5) return;
                      setState(() {
                        _topHudHeight = size.height;
                      });
                    },
                    child: _FloatingTopHud(
                      state: _state,
                      species: species,
                      onOpenLog: _openLogDialog,
                      onOpenCode: _openCodeDialog,
                      onOpenDex: _openDexDialog,
                    ),
                  ),
                ),
                Positioned(
                  left: edgePadding,
                  right: edgePadding,
                  bottom: dockBottom,
                  child: _FloatingBottomDock(
                    onOpenControls: _openControlSheet,
                    onOpenBackgrounds: _openBackgroundGallery,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pet Display Panel ────────────────────────────────────────────────────────

class _PetDisplayPanel extends StatelessWidget {
  const _PetDisplayPanel({
    required this.species,
    required this.mood,
    required this.state,
    required this.engine,
    required this.now,
    required this.background,
    this.topOverlayReserve = 0,
    this.showTopBar = true,
    this.immersive = false,
  });

  final PetSpecies species;
  final PetMood mood;
  final PetSnapshot state;
  final PetEngine engine;
  final DateTime now;
  final _GameBackground background;
  final double topOverlayReserve;
  final bool showTopBar;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final stage = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(immersive ? 0 : 28),
        border: immersive ? null : Border.all(color: const Color(0xFF20363A), width: 4),
        gradient: LinearGradient(
          colors: background.gradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final petSize = _petSize(constraints.biggest);
          final clipRadius = immersive ? 0.0 : 24.0;
          final topInset = MediaQuery.paddingOf(context).top;
          // Reserve safe space under top HUD on all devices.
          final infoTop = immersive
              ? math.max(
                  topOverlayReserve,
                  compact ? topInset + 104.0 : topInset + 92.0,
                )
              : 14.0;
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(clipRadius),
                  child: CustomPaint(
                    painter: _ScenePatternPainter(background: background),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          background.glowColor,
                          Colors.transparent,
                        ],
                        radius: 0.85,
                        center: const Alignment(0, -0.1),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: infoTop,
                child: _FxBadge(text: _topText()),
              ),
              if (species.secret)
                Positioned(
                  right: 14,
                  top: infoTop,
                  child: const _FxBadge(text: 'SECRET', accent: true),
                ),
              Center(
                child: _FloatingPetWidget(
                  species: species,
                  mood: mood,
                  size: petSize,
                ),
              ),
              if (_bottomText().isNotEmpty)
                Positioned(
                  right: 14,
                  bottom: 54,
                  child: _FxBadge(text: _bottomText(), accent: !state.alive),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StatOverlay(state: state),
              ),
            ],
          );
        },
      ),
    );

    if (immersive) return stage;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTopBar) ...[
              const _TopBar(),
              const SizedBox(height: 16),
            ],
            Expanded(child: stage),
          ],
        ),
      ),
    );
  }

  String _topText() {
    if (!state.alive) return '...';
    if (species.stage == PetStage.egg) {
      final remain = engine.hatchRemaining(state, now);
      if (remain == null || remain == Duration.zero) return 'READY';
      return '孵化 ${PetEngine.formatDuration(remain)}';
    }
    if (state.sleeping) return 'Zzz';
    if (state.sick) return '!! 生病';
    if (state.hunger < 25) return '咕咕咕';
    if (state.energy < 20) return '累了...';
    return '';
  }

  String _bottomText() {
    if (!state.alive) return 'GAME OVER';
    if (state.poop >= 3) return '!! 要清洁';
    if (state.eventText != '平静' && state.eventText != '孵化中') return state.eventText;
    return '';
  }

  double _petSize(Size viewport) {
    final base =
        (math.min(viewport.width, viewport.height) * (immersive ? 0.62 : 0.46))
            .clamp(128.0, immersive ? 560.0 : 460.0);
    final growth = switch (species.stage) {
      PetStage.egg => 0.78,
      PetStage.baby => 0.9,
      PetStage.rookie => 1.0,
      PetStage.champion => 1.14,
      PetStage.ultimate => 1.28,
    };
    return base * growth;
  }
}

// ─── Control Panel (no scroll) ────────────────────────────────────────────────

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.state,
    required this.species,
    required this.engine,
    required this.now,
    required this.onAction,
  });

  final PetSnapshot state;
  final PetSpecies species;
  final PetEngine engine;
  final DateTime now;
  final ValueChanged<PetAction> onAction;

  Future<void> _confirmRestart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认重启？'),
        content: const Text('宠物将重置为新的数码蛋，图鉴和战绩会保留。\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC85343)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认重启'),
          ),
        ],
      ),
    );
    if (confirmed == true) onAction(PetAction.restart);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 980;
    final rules = {
      for (final action in PetAction.values)
        action: engine.actionRule(state, action, now),
    };
    final isEgg = species.stage == PetStage.egg;

    final actionArea = isEgg
        ? _EggSection(rule: rules[PetAction.hatch]!, onAction: onAction)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '日常照顾',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7A6A40),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: _PrimaryBtn(
                      label: '喂食',
                      icon: Icons.restaurant_outlined,
                      rule: rules[PetAction.feed]!,
                      onTap: () => onAction(PetAction.feed),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrimaryBtn(
                      label: '清洁',
                      icon: Icons.cleaning_services_outlined,
                      rule: rules[PetAction.clean]!,
                      onTap: () => onAction(PetAction.clean),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrimaryBtn(
                      label: '表扬',
                      icon: Icons.favorite_outline,
                      rule: rules[PetAction.praise]!,
                      onTap: () => onAction(PetAction.praise),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '训练与行动',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7A6A40),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ActivityBtn(
                    label: '训练',
                    icon: Icons.fitness_center_outlined,
                    rule: rules[PetAction.train]!,
                    onTap: () => onAction(PetAction.train),
                  ),
                  _ActivityBtn(
                    label: '探索',
                    icon: Icons.explore_outlined,
                    rule: rules[PetAction.explore]!,
                    onTap: () => onAction(PetAction.explore),
                  ),
                  _ActivityBtn(
                    label: '战斗',
                    icon: Icons.shield_outlined,
                    rule: rules[PetAction.battle]!,
                    onTap: () => onAction(PetAction.battle),
                  ),
                  _ActivityBtn(
                    label: '休息',
                    icon: Icons.bedtime_outlined,
                    rule: rules[PetAction.rest]!,
                    onTap: () => onAction(PetAction.rest),
                  ),
                ],
              ),
              if (state.sick) ...[
                const SizedBox(height: 10),
                _ContextAction(
                  label: '宠物正在生病，点击治疗',
                  icon: Icons.medical_services_outlined,
                  color: const Color(0xFFC85343),
                  rule: rules[PetAction.medicine]!,
                  onTap: () => onAction(PetAction.medicine),
                ),
              ],
            ],
          );

    final bottomBar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 16),
        Row(
          children: [
            Expanded(
              child: state.logs.isNotEmpty
                  ? Text(
                      state.logs.first,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5A4A2A),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox.shrink(),
            ),
            if (state.restartUnlocked || !state.alive) ...[
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () => _confirmRestart(context),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('重启', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC85343),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ],
        ),
      ],
    );

    if (isCompact) {
      // 手机：可滚动，不用 Spacer
      return Card(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusChips(state: state),
              const Divider(height: 16),
              actionArea,
              const SizedBox(height: 10),
              bottomBar,
            ],
          ),
        ),
      );
    }

    // 桌面：固定布局，Spacer 把底部栏推到底
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusChips(state: state),
            const Divider(height: 16),
            actionArea,
            const Spacer(),
            bottomBar,
          ],
        ),
      ),
    );
  }
}

// ─── Egg section ─────────────────────────────────────────────────────────────

class _EggSection extends StatelessWidget {
  const _EggSection({required this.rule, required this.onAction});
  final PetActionRule rule;
  final ValueChanged<PetAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: rule.enabled ? () => onAction(PetAction.hatch) : null,
            icon: const Icon(Icons.egg_outlined, size: 20),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('孵化', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(rule.hint, style: const TextStyle(fontSize: 11, height: 1.4)),
              ],
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF20363A), width: 2),
              ),
              backgroundColor: rule.enabled ? const Color(0xFF51A774) : const Color(0xFFD7D7D7),
              foregroundColor: rule.enabled ? Colors.white : const Color(0xFF8A8A8A),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Context action (e.g. sick → heal) ───────────────────────────────────────

class _ContextAction extends StatelessWidget {
  const _ContextAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.rule,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final PetActionRule rule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: rule.enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const Spacer(),
            if (!rule.enabled)
              Text(
                rule.hint,
                style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Status chips ─────────────────────────────────────────────────────────────

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.state});
  final PetSnapshot state;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, bool)>[];
    if (state.careMistakes > 0) chips.add(('${state.careMistakes} 失误', state.careMistakes >= 5));
    if (state.poop > 0) chips.add(('${state.poop} 便便', state.poop >= 2));
    if (state.forcedNextSpeciesId != null) chips.add(('隐藏胚体', false));
    if (state.restartUnlocked) chips.add(('重启已解锁', true));

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips
          .map(
            (c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.$2 ? const Color(0xFFFFE8D4) : const Color(0xFFFFF7DF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: c.$2 ? const Color(0xFFE8943A) : const Color(0xFFBBAA80),
                  width: 1.5,
                ),
              ),
              child: Text(
                c.$1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.$2 ? const Color(0xFFB85020) : const Color(0xFF5A4A2A),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Primary button (large, full width) ──────────────────────────────────────

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.rule,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final PetActionRule rule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: rule.enabled ? onTap : null,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFD4EDDA),
        disabledBackgroundColor: const Color(0xFFE8E8E8),
        foregroundColor: const Color(0xFF20363A),
        disabledForegroundColor: const Color(0xFF9A9A9A),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: rule.enabled ? const Color(0xFF4A9E6A) : const Color(0xFFBBBBBB),
            width: 1.5,
          ),
        ),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            rule.hint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, height: 1.2),
          ),
        ],
      ),
    );
  }
}

// ─── Activity button (compact, icon row) ─────────────────────────────────────

class _ActivityBtn extends StatelessWidget {
  const _ActivityBtn({
    required this.label,
    required this.icon,
    required this.rule,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final PetActionRule rule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: rule.hint,
      child: GestureDetector(
        onTap: rule.enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: rule.enabled ? const Color(0xFFEEF7FA) : const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: rule.enabled ? const Color(0xFF20363A) : const Color(0xFFBBBBBB),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: rule.enabled ? const Color(0xFF20363A) : const Color(0xFFAAAAAA),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: rule.enabled ? const Color(0xFF20363A) : const Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingTopHud extends StatelessWidget {
  const _FloatingTopHud({
    required this.state,
    required this.species,
    required this.onOpenLog,
    required this.onOpenCode,
    required this.onOpenDex,
  });

  final PetSnapshot state;
  final PetSpecies species;
  final VoidCallback onOpenLog;
  final Future<void> Function() onOpenCode;
  final VoidCallback onOpenDex;

  String _stageLogoAsset(PetStage stage) {
    return switch (stage) {
      PetStage.egg || PetStage.baby => 'assets/logo/pet_logo_baby_256.png',
      PetStage.rookie => 'assets/logo/pet_logo_rookie_256.png',
      PetStage.champion => 'assets/logo/pet_logo_champion_256.png',
      PetStage.ultimate => 'assets/logo/pet_logo_ultimate_256.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final logoAsset = _stageLogoAsset(species.stage);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xB31A2E32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x66FFFFFF), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x88FFFFFF), width: 1.1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x5520303E),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              logoAsset,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'YooPet',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                    color: Color(0xFFF7FAFF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${species.name} · ${state.wins}胜 · 图鉴${state.discovered.length}/${PetEngine.speciesPool.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD5E1EE),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            if (state.sick)
              const _FxBadge(text: '生病中', accent: true),
            if (state.eventText != '平静' && state.eventText != '孵化中') ...[
              const SizedBox(width: 6),
              _FxBadge(text: state.eventText),
            ],
          ],
          const SizedBox(width: 8),
          IconButton(
            onPressed: onOpenLog,
            tooltip: '成长记录',
            icon: const Icon(Icons.history_rounded, color: Color(0xFFBC6C16)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFF0DA),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onOpenCode,
            tooltip: '输入秘码',
            icon: const Icon(Icons.password_rounded, color: Color(0xFF1D6B85)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFDDF3FF),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onOpenDex,
            tooltip: '打开宠物图鉴',
            icon: const Icon(Icons.pets_rounded, color: Color(0xFFFF7A59)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFF1DD),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBottomDock extends StatelessWidget {
  const _FloatingBottomDock({
    required this.onOpenControls,
    required this.onOpenBackgrounds,
  });

  final VoidCallback onOpenControls;
  final VoidCallback onOpenBackgrounds;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GameNavOrb(
              icon: Icons.tune_rounded,
              label: '控制',
              tooltip: '控制',
              iconColor: const Color(0xFFB36800),
              gradient: const [Color(0xFFFFE8BE), Color(0xFFFFC875)],
              compact: compact,
              onTap: onOpenControls,
            ),
            SizedBox(width: compact ? 10 : 14),
            _GameNavOrb(
              icon: Icons.wallpaper_rounded,
              label: '背景',
              tooltip: '背景',
              iconColor: const Color(0xFF1D6B85),
              gradient: const [Color(0xFFC8EEFF), Color(0xFF9DDCFA)],
              compact: compact,
              onTap: onOpenBackgrounds,
            ),
          ],
        ),
      ),
    );
  }
}

class _GameNavOrb extends StatelessWidget {
  const _GameNavOrb({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.iconColor,
    required this.gradient,
    this.compact = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final Color iconColor;
  final List<Color> gradient;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 42 : 50,
              height: compact ? 42 : 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x66FFFFFF), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.35),
                    blurRadius: compact ? 8 : 12,
                    offset: Offset(0, compact ? 3 : 5),
                  ),
                ],
              ),
              child: Icon(icon, size: compact ? 18 : 22, color: iconColor),
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF9FAFC),
                  shadows: [
                    Shadow(color: Color(0xAA102327), blurRadius: 2),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BackgroundDexCard extends StatelessWidget {
  const _BackgroundDexCard({
    required this.background,
    required this.unlocked,
    required this.active,
    required this.onTap,
  });

  final _GameBackground background;
  final bool unlocked;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? const Color(0xFF20363A) : const Color(0xFFD8CFAE),
            width: active ? 2.2 : 1.2,
          ),
          gradient: LinearGradient(
            colors: background.gradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ScenePatternPainter(background: background),
              ),
            ),
            if (!unlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xB3171C28),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          background.icon,
                          size: 18,
                          color: unlocked ? Colors.white : const Color(0xFFE8E8E8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            background.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: unlocked ? Colors.white : const Color(0xFFE8E8E8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      background.tagline,
                      style: TextStyle(
                        fontSize: 11,
                        color: unlocked ? Colors.white70 : const Color(0xFFD3D3D3),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      background.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: unlocked ? Colors.white : const Color(0xFFE8E8E8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: unlocked ? const Color(0xDDF7FAFF) : const Color(0x66FFFFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        active
                            ? '使用中'
                            : unlocked
                                ? '点击启用'
                                : '未解锁 · ${background.unlockHint}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: unlocked ? const Color(0xFF20363A) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!unlocked)
              const Positioned(
                right: 12,
                top: 10,
                child: Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _DexPetCard extends StatelessWidget {
  const _DexPetCard({
    required this.species,
    required this.unlocked,
    required this.evolvesTo,
  });

  final PetSpecies species;
  final bool unlocked;
  final List<PetSpecies> evolvesTo;

  @override
  Widget build(BuildContext context) {
    final stageName = PetEngine.stageNames[species.stage] ?? '';
    final previewNames = evolvesTo.take(4).map((s) => s.name).join(' / ');
    final evolveText = evolvesTo.isEmpty
        ? '终极形态 · 已到该分支顶点'
        : evolvesTo.length <= 4
            ? '下一阶段：$previewNames'
            : '下一阶段：$previewNames 等 ${evolvesTo.length} 种';

    Widget petView = _FloatingPetWidget(
      species: species,
      mood: _previewMood(species),
      size: 86,
    );
    if (!unlocked) {
      petView = Opacity(
        opacity: 0.92,
        child: petView,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFFFF8E6) : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked ? const Color(0xFF20363A) : const Color(0xFFC8C8C8),
          width: 1.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: unlocked ? const Color(0xFFEEF7FA) : const Color(0xFFE2E2E2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  stageName,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              if (species.secret)
                const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF5C74E2)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(child: petView),
                if (!unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xCC1A2E32),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '未解锁',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            species.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            species.line,
            style: const TextStyle(fontSize: 11, color: Color(0xFF7A6A40)),
          ),
          const SizedBox(height: 6),
          Text(
            evolveText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, height: 1.25, color: Color(0xFF5A4A2A)),
          ),
        ],
      ),
    );
  }

  PetMood _previewMood(PetSpecies species) {
    return switch (species.stage) {
      PetStage.egg => PetMood.idle,
      PetStage.baby => PetMood.happy,
      PetStage.rookie => PetMood.idle,
      PetStage.champion => PetMood.battle,
      PetStage.ultimate => PetMood.battle,
    };
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({
    required this.onChange,
    super.child,
  });

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_lastSize == newSize) return;
    _lastSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}

class _FxBadge extends StatelessWidget {
  const _FxBadge({required this.text, this.accent = false});
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent
            ? const Color(0xFFC85343).withValues(alpha: 0.9)
            : const Color(0xFFFFF7DF).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent ? const Color(0xFF8B0000) : const Color(0xFF20363A),
          width: 2,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: accent ? Colors.white : const Color(0xFF20363A),
        ),
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
          'YooPet',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12),
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

// ─── Stat overlay (inside pet viewport) ──────────────────────────────────────

class _StatOverlay extends StatelessWidget {
  const _StatOverlay({required this.state});
  final PetSnapshot state;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (Icons.restaurant_menu_outlined, state.hunger),
      (Icons.sentiment_satisfied_outlined, state.moodValue),
      (Icons.bolt_outlined, state.energy),
      (Icons.clean_hands_outlined, state.cleanliness),
      (Icons.military_tech_outlined, state.discipline),
      (Icons.shield_outlined, state.power),
    ];
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Container(
        color: const Color(0xDD1A2E32),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(
          children: stats.map((s) {
            final v = s.$2;
            final Color bar = v < 25
                ? const Color(0xFFFF6B5F)
                : v < 50
                    ? const Color(0xFFFFB74D)
                    : const Color(0xFF66BB6A);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 4, 5, 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(s.$1, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '$v',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (v / 100).clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: Colors.white24,
                          color: bar,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Scene painter ────────────────────────────────────────────────────────────

class _ScenePatternPainter extends CustomPainter {
  const _ScenePatternPainter({required this.background});

  final _GameBackground background;

  @override
  void paint(Canvas canvas, Size size) {
    final patternPaint = Paint()
      ..color = background.patternColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    switch (background.pattern) {
      case _BackdropPattern.dots:
        for (double y = 10; y < size.height; y += 24) {
          for (double x = 10; x < size.width; x += 24) {
            canvas.drawCircle(Offset(x, y), 1.2, Paint()..color = background.patternColor);
          }
        }
      case _BackdropPattern.sunsetLines:
        for (double y = 12; y < size.height; y += 26) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), patternPaint);
        }
      case _BackdropPattern.cyberGrid:
        for (double x = 0; x < size.width; x += 28) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), patternPaint);
        }
        for (double y = 0; y < size.height; y += 28) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), patternPaint);
        }
        final glow = Paint()
          ..color = background.patternColor.withValues(alpha: 0.3)
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset(0, size.height * 0.66),
          Offset(size.width, size.height * 0.66),
          glow,
        );
      case _BackdropPattern.mountain:
        final fill = Paint()
          ..color = background.patternColor.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill;
        final path = Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width * 0.18, size.height * 0.64)
          ..lineTo(size.width * 0.36, size.height)
          ..lineTo(size.width * 0.55, size.height * 0.58)
          ..lineTo(size.width * 0.8, size.height)
          ..lineTo(size.width, size.height * 0.68)
          ..lineTo(size.width, size.height)
          ..close();
        canvas.drawPath(path, fill);
      case _BackdropPattern.waves:
        final wave = Paint()
          ..color = background.patternColor
          ..strokeWidth = 1.3
          ..style = PaintingStyle.stroke;
        for (double y = size.height * 0.2; y < size.height; y += 24) {
          final path = Path();
          for (double x = 0; x <= size.width; x += 8) {
            final dy = math.sin((x / 40) + (y / 25)) * 4;
            if (x == 0) {
              path.moveTo(x, y + dy);
            } else {
              path.lineTo(x, y + dy);
            }
          }
          canvas.drawPath(path, wave);
        }
      case _BackdropPattern.runes:
        final fill = Paint()..color = background.patternColor.withValues(alpha: 0.16);
        for (double y = 18; y < size.height; y += 34) {
          for (double x = 16; x < size.width; x += 34) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(x, y), width: 12, height: 12),
                const Radius.circular(3),
              ),
              fill,
            );
          }
        }
    }

    _drawSceneProps(canvas, size);
  }

  void _drawSceneProps(Canvas canvas, Size size) {
    final cell = size.width < 640 ? 3.0 : 4.0;
    final baseY = size.height - (cell * 12);

    switch (background.pattern) {
      case _BackdropPattern.dots:
        _drawMeadowProps(canvas, size, cell, baseY);
      case _BackdropPattern.sunsetLines:
        _drawCampProps(canvas, size, cell, baseY);
      case _BackdropPattern.cyberGrid:
        _drawCyberProps(canvas, size, cell, baseY);
      case _BackdropPattern.mountain:
        _drawShrineProps(canvas, size, cell, baseY);
      case _BackdropPattern.waves:
        _drawOceanProps(canvas, size, cell, baseY);
      case _BackdropPattern.runes:
        _drawArchiveProps(canvas, size, cell, baseY);
    }
  }

  void _drawMeadowProps(Canvas canvas, Size size, double cell, double y) {
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.08, y),
      cell: cell,
      rows: const [
        '..ggg..',
        '.ggggg.',
        'ggggggg',
        '..ttt..',
        '..ttt..',
      ],
      palette: const {
        'g': Color(0xFF6FBF6B),
        't': Color(0xFF3E6A3A),
      },
    );
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.78, y + cell),
      cell: cell,
      rows: const [
        '..gg..',
        '.gffg.',
        'ggffgg',
        '..tt..',
      ],
      palette: const {
        'g': Color(0xFF7ACB72),
        'f': Color(0xFFFFD15E),
        't': Color(0xFF3E6A3A),
      },
    );
  }

  void _drawCampProps(Canvas canvas, Size size, double cell, double y) {
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.14, y + cell),
      cell: cell,
      rows: const [
        '..ff..',
        '.fyyf.',
        '..yy..',
        '.rrrr.',
        'rrrrrr',
      ],
      palette: const {
        'f': Color(0xFFFF6B3D),
        'y': Color(0xFFFFD05A),
        'r': Color(0xFF7A4A2E),
      },
    );
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.78, y + cell * 2),
      cell: cell,
      rows: const [
        'bbbbbb',
        'bddddb',
        'bddddb',
        'bbbbbb',
      ],
      palette: const {
        'b': Color(0xFF8F5A38),
        'd': Color(0xFFC48853),
      },
    );
  }

  void _drawCyberProps(Canvas canvas, Size size, double cell, double y) {
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.08, y - cell),
      cell: cell,
      rows: const [
        '..nn..',
        '.nccn.',
        'nccccn',
        'nccccn',
        '.nccn.',
        '..bb..',
        '..bb..',
      ],
      palette: const {
        'n': Color(0xFF1A3A58),
        'c': Color(0xFF53E3FF),
        'b': Color(0xFF2D5C7B),
      },
    );
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.78, y - cell),
      cell: cell,
      rows: const [
        '.nnnn.',
        '.nlln.',
        '.nlln.',
        '.nlln.',
        '.bbbb.',
      ],
      palette: const {
        'n': Color(0xFF213A56),
        'l': Color(0xFF7AF5FF),
        'b': Color(0xFF3A5C7E),
      },
    );
  }

  void _drawShrineProps(Canvas canvas, Size size, double cell, double y) {
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.1, y - cell * 2),
      cell: cell,
      rows: const [
        '..ss..',
        '.ssss.',
        'ssssss',
        'ssbbss',
        'ssbbss',
        'ssbbss',
      ],
      palette: const {
        's': Color(0xFFCBD9F5),
        'b': Color(0xFF8FA6D7),
      },
    );
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.78, y - cell * 2),
      cell: cell,
      rows: const [
        '..ss..',
        '.ssss.',
        'ssssss',
        'ssbbss',
        'ssbbss',
        'ssbbss',
      ],
      palette: const {
        's': Color(0xFFCBD9F5),
        'b': Color(0xFF8FA6D7),
      },
    );
  }

  void _drawOceanProps(Canvas canvas, Size size, double cell, double y) {
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.1, y + cell),
      cell: cell,
      rows: const [
        '..cc..',
        '.cccc.',
        'ccmccc',
        '.cmmc.',
        '..cc..',
      ],
      palette: const {
        'c': Color(0xFF51B8D9),
        'm': Color(0xFF7DE2E9),
      },
    );
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.76, y + cell),
      cell: cell,
      rows: const [
        '.rrrr.',
        'rrssrr',
        '.rssr.',
        '..bb..',
        '..bb..',
      ],
      palette: const {
        'r': Color(0xFF4E7993),
        's': Color(0xFFA5DCEF),
        'b': Color(0xFF2F5D75),
      },
    );
  }

  void _drawArchiveProps(Canvas canvas, Size size, double cell, double y) {
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.09, y - cell),
      cell: cell,
      rows: const [
        '..rr..',
        '.rrrr.',
        'rrssrr',
        '.rssr.',
        '..bb..',
        '..bb..',
      ],
      palette: const {
        'r': Color(0xFF6A7E92),
        's': Color(0xFF9ED9CB),
        'b': Color(0xFF3F4E67),
      },
    );
    _drawSprite(
      canvas,
      origin: Offset(size.width * 0.78, y - cell),
      cell: cell,
      rows: const [
        '..nn..',
        '.nccn.',
        'nccccn',
        '.nccn.',
        '..bb..',
      ],
      palette: const {
        'n': Color(0xFF37435B),
        'c': Color(0xFF8ED9C2),
        'b': Color(0xFF2A3448),
      },
    );
  }

  void _drawSprite(
    Canvas canvas, {
    required Offset origin,
    required double cell,
    required List<String> rows,
    required Map<String, Color> palette,
  }) {
    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final symbol = row[x];
        if (symbol == '.') continue;
        final color = palette[symbol];
        if (color == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(origin.dx + (x * cell), origin.dy + (y * cell), cell, cell),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePatternPainter oldDelegate) {
    return oldDelegate.background.id != background.id;
  }
}

// ─── Floating Pet Widget ──────────────────────────────────────────────────────

class _FloatingPetWidget extends StatefulWidget {
  const _FloatingPetWidget({
    required this.species,
    required this.mood,
    required this.size,
  });

  final PetSpecies species;
  final PetMood mood;
  final double size;

  @override
  State<_FloatingPetWidget> createState() => _FloatingPetWidgetState();
}

class _FloatingPetWidgetState extends State<_FloatingPetWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late _PetMotionProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = _profileForMood(widget.mood);
    _controller = AnimationController(
      vsync: this,
      duration: _profile.cycle,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _FloatingPetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood == widget.mood) return;
    _profile = _profileForMood(widget.mood);
    _controller.duration = _profile.cycle;
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final walkWave = math.sin(t * math.pi * 2);
        final fastWave = math.sin(t * math.pi * 12);
        final stepWave = math.sin(t * math.pi * 4);
        final pulseWave = math.sin(t * math.pi * 2).abs();
        final dx = walkWave * _profile.walkAmplitude + fastWave * _profile.shakeAmplitude;
        final dy = stepWave * _profile.bobAmplitude;
        final scale = 1 + (pulseWave * _profile.pulseAmplitude);
        final tilt = math.sin(t * math.pi * 2) * _profile.tiltAmplitude;
        final shadowScale = 1 - (pulseWave * _profile.shadowPulseAmplitude);
        final faceRight = walkWave >= 0;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ..._moodFx(t),
            Positioned(
              bottom: -(widget.size * 0.2),
              child: Transform.scale(
                scale: shadowScale,
                child: Container(
                  width: widget.size * 0.62,
                  height: widget.size * 0.14,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: tilt,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(faceRight ? 1.0 : -1.0, 1.0, 1.0),
                  child: Transform.scale(
                    scale: scale,
                    child: PixelPet(
                      species: widget.species,
                      mood: widget.mood,
                      size: widget.size,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _moodFx(double t) {
    final phase = t * math.pi * 2;
    final top = -widget.size * 0.42;
    switch (widget.mood) {
      case PetMood.happy:
        return [
          _fxIcon(
            icon: Icons.favorite_rounded,
            color: const Color(0xFFFF6FA8),
            dx: math.sin(phase) * 24,
            dy: top + math.cos(phase * 2) * 6,
            scale: 0.9 + math.sin(phase).abs() * 0.22,
          ),
          _fxIcon(
            icon: Icons.favorite_rounded,
            color: const Color(0xFFFF98BC),
            dx: math.sin(phase + 1.8) * 30,
            dy: top + 16 + math.cos((phase + 1.8) * 2.2) * 6,
            scale: 0.72 + math.sin(phase + 1.2).abs() * 0.18,
            opacity: 0.82,
          ),
        ];
      case PetMood.battle:
        return [
          _fxIcon(
            icon: Icons.flash_on_rounded,
            color: const Color(0xFFFFC940),
            dx: math.sin(phase * 1.6) * 38,
            dy: top + 16,
            scale: 0.9 + math.sin(phase * 2).abs() * 0.3,
          ),
          _fxIcon(
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF7043),
            dx: math.cos(phase * 1.8) * 30,
            dy: top + 36 + math.sin(phase * 2.1) * 8,
            scale: 0.72 + math.sin(phase + 0.8).abs() * 0.2,
          ),
        ];
      case PetMood.sleepy:
        return [
          _fxText(
            text: 'Z',
            color: const Color(0xFFD8EAFF),
            dx: 10 + math.sin(phase) * 10,
            dy: top - 6 + math.cos(phase) * 4,
            scale: 0.95 + math.sin(phase).abs() * 0.2,
            opacity: 0.9,
          ),
          _fxText(
            text: 'z',
            color: const Color(0xFFC3DBFF),
            dx: 24 + math.sin(phase + 1.4) * 8,
            dy: top + 14 + math.cos(phase + 0.8) * 4,
            scale: 0.78 + math.sin(phase + 0.8).abs() * 0.16,
            opacity: 0.82,
          ),
        ];
      case PetMood.sick:
        return [
          _fxIcon(
            icon: Icons.sick_rounded,
            color: const Color(0xFFA8FFB4),
            dx: math.sin(phase * 1.1) * 16,
            dy: top + 10 + math.cos(phase * 2) * 8,
            scale: 0.8 + math.sin(phase).abs() * 0.12,
            opacity: 0.9,
          ),
          _fxIcon(
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF8AC6FF),
            dx: -18 + math.sin(phase + 1.5) * 8,
            dy: top + 30 + math.cos(phase + 0.7) * 6,
            scale: 0.7 + math.sin(phase + 0.7).abs() * 0.12,
            opacity: 0.84,
          ),
        ];
      case PetMood.sad:
        return [
          _fxIcon(
            icon: Icons.cloud_rounded,
            color: const Color(0xFFB7C4D9),
            dx: math.sin(phase * 0.8) * 16,
            dy: top + 8,
            scale: 0.92,
            opacity: 0.82,
          ),
          _fxIcon(
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF82B6F2),
            dx: -14 + math.sin(phase + 1.2) * 10,
            dy: top + 24 + math.cos(phase + 0.5) * 8,
            scale: 0.72 + math.sin(phase).abs() * 0.1,
            opacity: 0.8,
          ),
        ];
      case PetMood.idle:
        return const [];
    }
  }

  Widget _fxIcon({
    required IconData icon,
    required Color color,
    required double dx,
    required double dy,
    required double scale,
    double opacity = 1,
  }) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  Widget _fxText({
    required String text,
    required Color color,
    required double dx,
    required double dy,
    required double scale,
    double opacity = 1,
  }) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  _PetMotionProfile _profileForMood(PetMood mood) {
    switch (mood) {
      case PetMood.sleepy:
        return const _PetMotionProfile(
          cycle: Duration(milliseconds: 3600),
          walkAmplitude: 6,
          bobAmplitude: 2.4,
          pulseAmplitude: 0.01,
          tiltAmplitude: 0.02,
          shakeAmplitude: 0,
          shadowPulseAmplitude: 0.02,
        );
      case PetMood.happy:
        return const _PetMotionProfile(
          cycle: Duration(milliseconds: 1900),
          walkAmplitude: 20,
          bobAmplitude: 5.5,
          pulseAmplitude: 0.03,
          tiltAmplitude: 0.08,
          shakeAmplitude: 0,
          shadowPulseAmplitude: 0.08,
        );
      case PetMood.battle:
        return const _PetMotionProfile(
          cycle: Duration(milliseconds: 1500),
          walkAmplitude: 24,
          bobAmplitude: 3.8,
          pulseAmplitude: 0.06,
          tiltAmplitude: 0.12,
          shakeAmplitude: 1.8,
          shadowPulseAmplitude: 0.12,
        );
      case PetMood.sick:
      case PetMood.sad:
        return const _PetMotionProfile(
          cycle: Duration(milliseconds: 3000),
          walkAmplitude: 8,
          bobAmplitude: 2.2,
          pulseAmplitude: 0.015,
          tiltAmplitude: 0.03,
          shakeAmplitude: 0.6,
          shadowPulseAmplitude: 0.03,
        );
      case PetMood.idle:
        return const _PetMotionProfile(
          cycle: Duration(milliseconds: 2400),
          walkAmplitude: 14,
          bobAmplitude: 4,
          pulseAmplitude: 0.02,
          tiltAmplitude: 0.04,
          shakeAmplitude: 0,
          shadowPulseAmplitude: 0.05,
        );
    }
  }
}

class _PetMotionProfile {
  const _PetMotionProfile({
    required this.cycle,
    required this.walkAmplitude,
    required this.bobAmplitude,
    required this.pulseAmplitude,
    required this.tiltAmplitude,
    required this.shakeAmplitude,
    required this.shadowPulseAmplitude,
  });

  final Duration cycle;
  final double walkAmplitude;
  final double bobAmplitude;
  final double pulseAmplitude;
  final double tiltAmplitude;
  final double shakeAmplitude;
  final double shadowPulseAmplitude;
}
