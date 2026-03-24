import 'dart:math';

enum PetStage { egg, baby, rookie, champion, ultimate }

enum PetAction {
  hatch,
  feed,
  train,
  explore,
  clean,
  rest,
  battle,
  praise,
  medicine,
  restart,
}

enum PetMood { idle, happy, battle, sleepy, sick, sad }

class PetActionRule {
  const PetActionRule({
    required this.enabled,
    required this.hint,
  });

  final bool enabled;
  final String hint;
}

class PetSpecies {
  const PetSpecies({
    required this.id,
    required this.name,
    required this.stage,
    required this.line,
    required this.body,
    required this.primary,
    required this.secondary,
    required this.face,
    required this.traits,
    this.secret = false,
  });

  final String id;
  final String name;
  final PetStage stage;
  final String line;
  final String body;
  final int primary;
  final int secondary;
  final String face;
  final List<String> traits;
  final bool secret;
}

class PetSnapshot {
  PetSnapshot({
    required this.speciesId,
    required this.age,
    required this.hunger,
    required this.moodValue,
    required this.energy,
    required this.cleanliness,
    required this.discipline,
    required this.power,
    required this.wins,
    required this.poop,
    required this.careMistakes,
    required this.discovered,
    required this.logs,
    required this.usedCodes,
    required this.sleeping,
    required this.sick,
    required this.alive,
    required this.eventText,
    required this.lastAction,
    required this.createdAt,
    required this.hatchReadyAt,
    required this.lastDecayAt,
    required this.lastExploreChargeAt,
    required this.lastBattleChargeAt,
    required this.cooldowns,
    required this.exploreCharges,
    required this.battleCharges,
    required this.restartUnlocked,
    required this.unlockedBackgroundIds,
    required this.activeBackgroundId,
    required this.sleepEndsAt,
    required this.forcedNextSpeciesId,
  });

  static const Object _unset = Object();

  factory PetSnapshot.initial({
    DateTime? now,
    List<String>? discovered,
    List<String>? usedCodes,
    List<String>? unlockedBackgroundIds,
    String? activeBackgroundId,
  }) {
    final created = now ?? DateTime.now();
    final dex = <String>{'egg', ...(discovered ?? const <String>[])}.toList();
    const defaultBackgroundId = 'meadow_day';
    final unlocked = <String>{defaultBackgroundId, ...(unlockedBackgroundIds ?? const <String>[])}
        .toList();
    return PetSnapshot(
      speciesId: 'egg',
      age: 0,
      hunger: 74,
      moodValue: 72,
      energy: 76,
      cleanliness: 92,
      discipline: 38,
      power: 16,
      wins: 0,
      poop: 0,
      careMistakes: 0,
      discovered: dex,
      logs: ['欢迎回来，数码蛋正在静静孵化。'],
      usedCodes: usedCodes ?? const <String>[],
      sleeping: false,
      sick: false,
      alive: true,
      eventText: '孵化中',
      lastAction: PetAction.hatch,
      createdAt: created,
      hatchReadyAt: created.add(PetEngine.hatchDuration),
      lastDecayAt: created,
      lastExploreChargeAt: created,
      lastBattleChargeAt: created,
      cooldowns: const {},
      exploreCharges: PetEngine.maxExploreCharges,
      battleCharges: PetEngine.maxBattleCharges,
      restartUnlocked: false,
      unlockedBackgroundIds: unlocked,
      activeBackgroundId:
          unlocked.contains(activeBackgroundId) ? (activeBackgroundId ?? defaultBackgroundId) : defaultBackgroundId,
      sleepEndsAt: null,
      forcedNextSpeciesId: null,
    );
  }

  factory PetSnapshot.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final cooldownsJson = (json['cooldowns'] as Map?)?.cast<String, dynamic>() ?? const {};
    final discovered = ((json['discovered'] as List?) ?? const <dynamic>[])
        .map((item) => '$item')
        .toList();
    final usedCodes = ((json['usedCodes'] as List?) ?? const <dynamic>[])
        .map((item) => '$item')
        .toList();
    final unlockedBackgroundIds = <String>{
      'meadow_day',
      ...((json['unlockedBackgroundIds'] as List?) ?? const <dynamic>[]).map((item) => '$item'),
    }.toList();
    final requestedBackgroundId = json['activeBackgroundId'] as String? ?? 'meadow_day';
    return PetSnapshot(
      speciesId: json['speciesId'] as String? ?? 'egg',
      age: (json['age'] as num?)?.toInt() ?? 0,
      hunger: (json['hunger'] as num?)?.toDouble() ?? 74,
      moodValue: (json['moodValue'] as num?)?.toDouble() ?? 72,
      energy: (json['energy'] as num?)?.toDouble() ?? 76,
      cleanliness: (json['cleanliness'] as num?)?.toDouble() ?? 92,
      discipline: (json['discipline'] as num?)?.toDouble() ?? 38,
      power: (json['power'] as num?)?.toDouble() ?? 16,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      poop: (json['poop'] as num?)?.toInt() ?? 0,
      careMistakes: (json['careMistakes'] as num?)?.toInt() ?? 0,
      discovered: <String>{'egg', ...discovered}.toList(),
      logs: ((json['logs'] as List?) ?? const <dynamic>[])
          .map((item) => '$item')
          .toList()
        ..removeWhere((item) => item.trim().isEmpty),
      usedCodes: usedCodes,
      sleeping: json['sleeping'] as bool? ?? false,
      sick: json['sick'] as bool? ?? false,
      alive: json['alive'] as bool? ?? true,
      eventText: json['eventText'] as String? ?? '平静',
      lastAction: PetAction.values.firstWhere(
        (value) => value.name == (json['lastAction'] as String? ?? ''),
        orElse: () => PetAction.hatch,
      ),
      createdAt: _parseDateTime(json['createdAt'], now),
      hatchReadyAt: _parseDateTime(json['hatchReadyAt'], now.add(PetEngine.hatchDuration)),
      lastDecayAt: _parseDateTime(json['lastDecayAt'], now),
      lastExploreChargeAt: _parseDateTime(json['lastExploreChargeAt'], now),
      lastBattleChargeAt: _parseDateTime(json['lastBattleChargeAt'], now),
      cooldowns: cooldownsJson.map(
        (key, value) => MapEntry(key, _parseDateTime(value, now)),
      ),
      exploreCharges: (json['exploreCharges'] as num?)?.toInt() ?? PetEngine.maxExploreCharges,
      battleCharges: (json['battleCharges'] as num?)?.toInt() ?? PetEngine.maxBattleCharges,
      restartUnlocked: json['restartUnlocked'] as bool? ?? false,
      unlockedBackgroundIds: unlockedBackgroundIds,
      activeBackgroundId: unlockedBackgroundIds.contains(requestedBackgroundId)
          ? requestedBackgroundId
          : 'meadow_day',
      sleepEndsAt: json['sleepEndsAt'] == null ? null : _parseDateTime(json['sleepEndsAt'], now),
      forcedNextSpeciesId: json['forcedNextSpeciesId'] as String?,
    );
  }

  final String speciesId;
  final int age;
  final double hunger;
  final double moodValue;
  final double energy;
  final double cleanliness;
  final double discipline;
  final double power;
  final int wins;
  final int poop;
  final int careMistakes;
  final List<String> discovered;
  final List<String> logs;
  final List<String> usedCodes;
  final bool sleeping;
  final bool sick;
  final bool alive;
  final String eventText;
  final PetAction lastAction;
  final DateTime createdAt;
  final DateTime hatchReadyAt;
  final DateTime lastDecayAt;
  final DateTime lastExploreChargeAt;
  final DateTime lastBattleChargeAt;
  final Map<String, DateTime> cooldowns;
  final int exploreCharges;
  final int battleCharges;
  final bool restartUnlocked;
  final List<String> unlockedBackgroundIds;
  final String activeBackgroundId;
  final DateTime? sleepEndsAt;
  final String? forcedNextSpeciesId;

  Map<String, dynamic> toJson() {
    return {
      'speciesId': speciesId,
      'age': age,
      'hunger': hunger,
      'moodValue': moodValue,
      'energy': energy,
      'cleanliness': cleanliness,
      'discipline': discipline,
      'power': power,
      'wins': wins,
      'poop': poop,
      'careMistakes': careMistakes,
      'discovered': discovered,
      'logs': logs,
      'usedCodes': usedCodes,
      'sleeping': sleeping,
      'sick': sick,
      'alive': alive,
      'eventText': eventText,
      'lastAction': lastAction.name,
      'createdAt': createdAt.toIso8601String(),
      'hatchReadyAt': hatchReadyAt.toIso8601String(),
      'lastDecayAt': lastDecayAt.toIso8601String(),
      'lastExploreChargeAt': lastExploreChargeAt.toIso8601String(),
      'lastBattleChargeAt': lastBattleChargeAt.toIso8601String(),
      'cooldowns': cooldowns.map((key, value) => MapEntry(key, value.toIso8601String())),
      'exploreCharges': exploreCharges,
      'battleCharges': battleCharges,
      'restartUnlocked': restartUnlocked,
      'unlockedBackgroundIds': unlockedBackgroundIds,
      'activeBackgroundId': activeBackgroundId,
      'sleepEndsAt': sleepEndsAt?.toIso8601String(),
      'forcedNextSpeciesId': forcedNextSpeciesId,
    };
  }

  PetSnapshot copyWith({
    String? speciesId,
    int? age,
    double? hunger,
    double? moodValue,
    double? energy,
    double? cleanliness,
    double? discipline,
    double? power,
    int? wins,
    int? poop,
    int? careMistakes,
    List<String>? discovered,
    List<String>? logs,
    List<String>? usedCodes,
    bool? sleeping,
    bool? sick,
    bool? alive,
    String? eventText,
    PetAction? lastAction,
    DateTime? createdAt,
    DateTime? hatchReadyAt,
    DateTime? lastDecayAt,
    DateTime? lastExploreChargeAt,
    DateTime? lastBattleChargeAt,
    Map<String, DateTime>? cooldowns,
    int? exploreCharges,
    int? battleCharges,
    bool? restartUnlocked,
    List<String>? unlockedBackgroundIds,
    String? activeBackgroundId,
    Object? sleepEndsAt = _unset,
    Object? forcedNextSpeciesId = _unset,
  }) {
    return PetSnapshot(
      speciesId: speciesId ?? this.speciesId,
      age: age ?? this.age,
      hunger: hunger ?? this.hunger,
      moodValue: moodValue ?? this.moodValue,
      energy: energy ?? this.energy,
      cleanliness: cleanliness ?? this.cleanliness,
      discipline: discipline ?? this.discipline,
      power: power ?? this.power,
      wins: wins ?? this.wins,
      poop: poop ?? this.poop,
      careMistakes: careMistakes ?? this.careMistakes,
      discovered: discovered ?? this.discovered,
      logs: logs ?? this.logs,
      usedCodes: usedCodes ?? this.usedCodes,
      sleeping: sleeping ?? this.sleeping,
      sick: sick ?? this.sick,
      alive: alive ?? this.alive,
      eventText: eventText ?? this.eventText,
      lastAction: lastAction ?? this.lastAction,
      createdAt: createdAt ?? this.createdAt,
      hatchReadyAt: hatchReadyAt ?? this.hatchReadyAt,
      lastDecayAt: lastDecayAt ?? this.lastDecayAt,
      lastExploreChargeAt: lastExploreChargeAt ?? this.lastExploreChargeAt,
      lastBattleChargeAt: lastBattleChargeAt ?? this.lastBattleChargeAt,
      cooldowns: cooldowns ?? this.cooldowns,
      exploreCharges: exploreCharges ?? this.exploreCharges,
      battleCharges: battleCharges ?? this.battleCharges,
      restartUnlocked: restartUnlocked ?? this.restartUnlocked,
      unlockedBackgroundIds: unlockedBackgroundIds ?? this.unlockedBackgroundIds,
      activeBackgroundId: activeBackgroundId ?? this.activeBackgroundId,
      sleepEndsAt: identical(sleepEndsAt, _unset) ? this.sleepEndsAt : sleepEndsAt as DateTime?,
      forcedNextSpeciesId: identical(forcedNextSpeciesId, _unset)
          ? this.forcedNextSpeciesId
          : forcedNextSpeciesId as String?,
    );
  }

  static DateTime _parseDateTime(Object? raw, DateTime fallback) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw) ?? fallback;
    }
    return fallback;
  }
}

class PetEngine {
  PetEngine() : _random = Random();

  final Random _random;

  static const hatchDuration = Duration(minutes: 3);
  static const decayTurn = Duration(minutes: 5);
  static const exploreRefill = Duration(minutes: 30);
  static const battleRefill = Duration(minutes: 45);
  static const maxExploreCharges = 3;
  static const maxBattleCharges = 2;

  static const actionLabels = {
    PetAction.hatch: '孵化',
    PetAction.feed: '喂食',
    PetAction.train: '训练',
    PetAction.explore: '探索',
    PetAction.clean: '清洁',
    PetAction.rest: '休息',
    PetAction.battle: '战斗',
    PetAction.praise: '表扬',
    PetAction.medicine: '治疗',
    PetAction.restart: '重启舱',
  };

  static const actionCooldowns = {
    PetAction.feed: Duration(minutes: 5),
    PetAction.train: Duration(minutes: 10),
    PetAction.explore: Duration(minutes: 20),
    PetAction.clean: Duration(minutes: 2),
    PetAction.rest: Duration(minutes: 5),
    PetAction.battle: Duration(minutes: 25),
    PetAction.praise: Duration(minutes: 8),
    PetAction.medicine: Duration(minutes: 12),
  };

  static const stageNames = {
    PetStage.egg: '数码蛋',
    PetStage.baby: '幼年期',
    PetStage.rookie: '成长期',
    PetStage.champion: '成熟期',
    PetStage.ultimate: '完全体',
  };

  static const List<PetSpecies> speciesPool = [
    PetSpecies(
      id: 'egg',
      name: '数码蛋',
      stage: PetStage.egg,
      line: '未定',
      body: 'egg',
      primary: 0xFFF4FFFA,
      secondary: 0xFFB7E7DB,
      face: 'dot',
      traits: ['cheek'],
    ),
    PetSpecies(
      id: 'bubble',
      name: '泡泡团兽',
      stage: PetStage.baby,
      line: '暖光系',
      body: 'blob',
      primary: 0xFFFFF1C2,
      secondary: 0xFFFFC47C,
      face: 'smile',
      traits: ['cheek'],
    ),
    PetSpecies(
      id: 'mint',
      name: '薄荷豆兽',
      stage: PetStage.baby,
      line: '森林系',
      body: 'blob',
      primary: 0xFFE2FFE9,
      secondary: 0xFF87D6A7,
      face: 'wide',
      traits: ['leaf'],
    ),
    PetSpecies(
      id: 'pearl',
      name: '珍珠团兽',
      stage: PetStage.baby,
      line: '星梦系',
      body: 'blob',
      primary: 0xFFFFECFF,
      secondary: 0xFFF6A6D8,
      face: 'joy',
      traits: ['cheek'],
    ),
    PetSpecies(
      id: 'ember',
      name: '余烬牙兽',
      stage: PetStage.baby,
      line: '烈焰系',
      body: 'cat',
      primary: 0xFFFFE2BD,
      secondary: 0xFFFF9459,
      face: 'smile',
      traits: ['horn'],
    ),
    PetSpecies(
      id: 'sprout',
      name: '芽芽果兽',
      stage: PetStage.baby,
      line: '森林系',
      body: 'seed',
      primary: 0xFFF0FFD9,
      secondary: 0xFFADE06B,
      face: 'wide',
      traits: ['leaf'],
    ),
    PetSpecies(
      id: 'gloom',
      name: '雾雾幽兽',
      stage: PetStage.baby,
      line: '夜影系',
      body: 'ghost',
      primary: 0xFFECEFFF,
      secondary: 0xFFA5AEF0,
      face: 'flat',
      traits: [],
    ),
    PetSpecies(
      id: 'cipher',
      name: '秘码团兽',
      stage: PetStage.baby,
      line: '秘藏系',
      body: 'blob',
      primary: 0xFFE8F7FF,
      secondary: 0xFF67C3FF,
      face: 'wide',
      traits: ['cheek', 'leaf'],
      secret: true,
    ),
    PetSpecies(
      id: 'sunbit',
      name: '晴光兽',
      stage: PetStage.rookie,
      line: '暖光系',
      body: 'cat',
      primary: 0xFFFFF5AB,
      secondary: 0xFFFFC66A,
      face: 'joy',
      traits: ['cheek'],
    ),
    PetSpecies(
      id: 'flare',
      name: '火牙兽',
      stage: PetStage.rookie,
      line: '烈焰系',
      body: 'dragon',
      primary: 0xFFFFD39E,
      secondary: 0xFFFF7E46,
      face: 'angry',
      traits: ['horn', 'tail'],
    ),
    PetSpecies(
      id: 'moss',
      name: '青苔甲兽',
      stage: PetStage.rookie,
      line: '森林系',
      body: 'golem',
      primary: 0xFFE5F8D0,
      secondary: 0xFF7EB46A,
      face: 'dot',
      traits: ['leaf', 'armor'],
    ),
    PetSpecies(
      id: 'glint',
      name: '闪闪翼兽',
      stage: PetStage.rookie,
      line: '星梦系',
      body: 'bird',
      primary: 0xFFFFF0D9,
      secondary: 0xFFD6A8F4,
      face: 'joy',
      traits: ['wing'],
    ),
    PetSpecies(
      id: 'mist',
      name: '雾角兽',
      stage: PetStage.rookie,
      line: '夜影系',
      body: 'ghost',
      primary: 0xFFF1F3FF,
      secondary: 0xFF9099E3,
      face: 'flat',
      traits: ['horn'],
    ),
    PetSpecies(
      id: 'tidal',
      name: '潮鳍兽',
      stage: PetStage.rookie,
      line: '深海系',
      body: 'dragon',
      primary: 0xFFD8FBFF,
      secondary: 0xFF5DB9D4,
      face: 'smile',
      traits: ['tail'],
    ),
    PetSpecies(
      id: 'spark',
      name: '电啾兽',
      stage: PetStage.rookie,
      line: '雷鸣系',
      body: 'cat',
      primary: 0xFFFFF19F,
      secondary: 0xFFF4CF47,
      face: 'angry',
      traits: ['horn'],
    ),
    PetSpecies(
      id: 'glitch',
      name: '断章兽',
      stage: PetStage.rookie,
      line: '秘藏系',
      body: 'bird',
      primary: 0xFFEFF6FF,
      secondary: 0xFF6A9CFF,
      face: 'angry',
      traits: ['wing', 'horn'],
      secret: true,
    ),
    PetSpecies(
      id: 'aurora',
      name: '极光翼兽',
      stage: PetStage.champion,
      line: '星梦系',
      body: 'bird',
      primary: 0xFFFFF4FF,
      secondary: 0xFFC0A7FF,
      face: 'joy',
      traits: ['wing', 'armor'],
    ),
    PetSpecies(
      id: 'blaze',
      name: '烈焰小龙兽',
      stage: PetStage.champion,
      line: '烈焰系',
      body: 'dragon',
      primary: 0xFFFFD5B4,
      secondary: 0xFFFF6948,
      face: 'angry',
      traits: ['horn', 'tail', 'armor'],
    ),
    PetSpecies(
      id: 'thunder',
      name: '雷角虎机兽',
      stage: PetStage.champion,
      line: '雷鸣系',
      body: 'cat',
      primary: 0xFFFFF0A5,
      secondary: 0xFFE8BA31,
      face: 'angry',
      traits: ['horn', 'armor'],
    ),
    PetSpecies(
      id: 'reef',
      name: '珊潮海兽',
      stage: PetStage.champion,
      line: '深海系',
      body: 'dragon',
      primary: 0xFFDCF9FF,
      secondary: 0xFF4FAFD0,
      face: 'wide',
      traits: ['tail', 'wing'],
    ),
    PetSpecies(
      id: 'bloom',
      name: '森芽守护兽',
      stage: PetStage.champion,
      line: '森林系',
      body: 'golem',
      primary: 0xFFEFFFDA,
      secondary: 0xFF73AE63,
      face: 'dot',
      traits: ['leaf', 'armor'],
    ),
    PetSpecies(
      id: 'dusk',
      name: '夜幕灵兽',
      stage: PetStage.champion,
      line: '夜影系',
      body: 'ghost',
      primary: 0xFFEDEFFF,
      secondary: 0xFF767ED2,
      face: 'angry',
      traits: ['horn', 'wing'],
    ),
    PetSpecies(
      id: 'sigil',
      name: '印纹龙兽',
      stage: PetStage.champion,
      line: '秘藏系',
      body: 'dragon',
      primary: 0xFFE6F5FF,
      secondary: 0xFF4C84FF,
      face: 'angry',
      traits: ['horn', 'tail', 'wing'],
      secret: true,
    ),
    PetSpecies(
      id: 'halo',
      name: '圣环团兽',
      stage: PetStage.ultimate,
      line: '暖光系',
      body: 'bird',
      primary: 0xFFFFFCEB,
      secondary: 0xFFFFDC84,
      face: 'joy',
      traits: ['wing', 'armor', 'cheek'],
    ),
    PetSpecies(
      id: 'nova',
      name: '星核龙兽',
      stage: PetStage.ultimate,
      line: '星梦系',
      body: 'dragon',
      primary: 0xFFFFE8FF,
      secondary: 0xFFFF85CA,
      face: 'angry',
      traits: ['horn', 'tail', 'wing'],
    ),
    PetSpecies(
      id: 'atlas',
      name: '巨岩甲兽',
      stage: PetStage.ultimate,
      line: '森林系',
      body: 'golem',
      primary: 0xFFE8F0C9,
      secondary: 0xFF91AE54,
      face: 'flat',
      traits: ['armor', 'horn'],
    ),
    PetSpecies(
      id: 'paradox',
      name: '零界圣兽',
      stage: PetStage.ultimate,
      line: '秘藏系',
      body: 'bird',
      primary: 0xFFF0F8FF,
      secondary: 0xFF4D7CFF,
      face: 'joy',
      traits: ['wing', 'armor', 'horn'],
      secret: true,
    ),
  ];

  static final Map<String, PetSpecies> speciesById = {
    for (final item in speciesPool) item.id: item,
  };

  PetSpecies speciesOf(PetSnapshot snapshot) => speciesById[snapshot.speciesId]!;

  PetMood moodOf(PetSnapshot snapshot) {
    if (!snapshot.alive) return PetMood.sad;
    if (snapshot.sleeping) return PetMood.sleepy;
    if (snapshot.sick) return PetMood.sick;
    if (snapshot.lastAction == PetAction.battle) return PetMood.battle;
    if (snapshot.lastAction == PetAction.feed ||
        snapshot.lastAction == PetAction.praise ||
        snapshot.lastAction == PetAction.explore) {
      return PetMood.happy;
    }
    if (snapshot.hunger < 30 || snapshot.cleanliness < 25) return PetMood.sad;
    return PetMood.idle;
  }

  PetSnapshot resolveTime(PetSnapshot current, DateTime now) {
    var next = _refillCharges(current, now);
    if (!next.alive) return next;

    if (next.sleeping && next.sleepEndsAt != null && !now.isBefore(next.sleepEndsAt!)) {
      next = _pushLog(
        next.copyWith(
          sleeping: false,
          sleepEndsAt: null,
          eventText: '醒来了',
        ),
        '它睡醒了，看起来精神好多了。',
      );
    }

    // 到点自动孵化，避免必须手动点击“孵化”。
    final speciesBeforeResolve = speciesOf(next);
    if (speciesBeforeResolve.stage == PetStage.egg && !now.isBefore(next.hatchReadyAt)) {
      next = _handleHatch(next, now).copyWith(lastAction: PetAction.hatch);
    }

    final elapsed = now.difference(next.lastDecayAt);
    // 最多补算 24 小时（288 个 5 分钟回合），超出部分进入保护状态
    const maxOfflineTurns = 288;
    var turns = elapsed.isNegative ? 0 : elapsed.inSeconds ~/ decayTurn.inSeconds;
    final bool longAbsence = elapsed.inMinutes > 60;
    if (turns > maxOfflineTurns) turns = maxOfflineTurns;
    if (turns <= 0) return next;

    final species = speciesOf(next);
    var hungerLoss = (next.sleeping ? 1.5 : 5.0) * turns;
    var moodLoss = 3.0 * turns;
    var energyDelta = (next.sleeping ? 9.0 : -3.0) * turns;
    var disciplineLoss = 0.5 * turns;
    var addedPoop = turns ~/ 6;
    // 卫生由便便事件驱动，不随时间自动衰减
    var cleanLoss = addedPoop * 10.0;

    if (species.stage == PetStage.egg) {
      hungerLoss = 0;
      moodLoss = 0;
      energyDelta = 0;
      cleanLoss = 0;
      disciplineLoss = 0;
      addedPoop = 0;
    }

    next = next.copyWith(
      age: species.stage == PetStage.egg ? next.age : next.age + turns,
      hunger: _clamp(next.hunger - hungerLoss),
      moodValue: _clamp(next.moodValue - moodLoss),
      energy: _clamp(next.energy + energyDelta),
      cleanliness: _clamp(next.cleanliness - cleanLoss),
      discipline: _clamp(next.discipline - disciplineLoss),
      poop: next.poop + addedPoop,
      lastDecayAt: next.lastDecayAt.add(Duration(seconds: turns * decayTurn.inSeconds)),
      eventText: next.sleeping ? '休息中' : '平静',
    );

    // 长时间离开后的返回叙事
    if (longAbsence && species.stage != PetStage.egg && next.alive) {
      final awayMin = elapsed.inMinutes.clamp(0, 24 * 60);
      final awayStr = awayMin >= 60
          ? '${awayMin ~/ 60} 小时${awayMin % 60 > 0 ? ' ${awayMin % 60} 分钟' : ''}'
          : '$awayMin 分钟';
      next = _pushLog(next, '${species.name} 独自等候了 $awayStr，看到你回来，它动了动。');
    }

    if (_needsSickness(next)) {
      next = next.copyWith(sick: true, eventText: '状态不佳');
    }

    if (_needsFailure(next)) {
      next = next.copyWith(careMistakes: next.careMistakes + 1);
    }

    if (next.careMistakes >= 8 || (next.sick && _criticalValues(next) >= 3)) {
      next = _pushLog(
        next.copyWith(alive: false, sleeping: false, sleepEndsAt: null, eventText: '已离开'),
        '你的宠物因为长期没有被好好照顾，离开了。',
      );
    }

    return _evolveIfNeeded(next);
  }

  PetActionRule actionRule(PetSnapshot snapshot, PetAction action, DateTime now) {
    final species = speciesOf(snapshot);
    final cooldown = cooldownRemaining(snapshot, action, now);

    if (action == PetAction.restart) {
      if (!snapshot.alive) return const PetActionRule(enabled: true, hint: '重新开始新的轮回');
      if (snapshot.restartUnlocked) return const PetActionRule(enabled: true, hint: '本次已获得重启权限');
      return const PetActionRule(enabled: false, hint: '需要秘码 RESET-KEY');
    }

    if (!snapshot.alive) {
      return const PetActionRule(enabled: false, hint: '宠物已离开');
    }

    if (action == PetAction.hatch) {
      if (species.stage != PetStage.egg) {
        return const PetActionRule(enabled: false, hint: '已经孵化完成');
      }
      if (now.isBefore(snapshot.hatchReadyAt)) {
        return PetActionRule(
          enabled: false,
          hint: '剩余 ${formatDuration(snapshot.hatchReadyAt.difference(now))}',
        );
      }
      return const PetActionRule(enabled: true, hint: '到点后才能破壳');
    }

    if (species.stage == PetStage.egg) {
      return const PetActionRule(enabled: false, hint: '蛋阶段只允许等待孵化');
    }

    if (snapshot.sleeping && action != PetAction.medicine && action != PetAction.clean) {
      return const PetActionRule(enabled: false, hint: '它正在睡觉');
    }

    if (cooldown != null) {
      return PetActionRule(
        enabled: false,
        hint: '冷却 ${formatDuration(cooldown)}',
      );
    }

    switch (action) {
      case PetAction.feed:
        return PetActionRule(
          enabled: true,
          hint: snapshot.hunger > 85 ? '太饱会有副作用' : '恢复饥饿值',
        );
      case PetAction.train:
        if (snapshot.energy < 28) {
          return const PetActionRule(enabled: false, hint: '体力太低');
        }
        return const PetActionRule(enabled: true, hint: '消耗体力提升战力');
      case PetAction.explore:
        if (snapshot.energy < 34) {
          return const PetActionRule(enabled: false, hint: '体力不足，无法外出');
        }
        if (snapshot.exploreCharges <= 0) {
          final remaining = exploreRefillRemaining(snapshot, now);
          return PetActionRule(
            enabled: false,
            hint: '补充中 ${formatDuration(remaining ?? Duration.zero)}',
          );
        }
        return PetActionRule(
          enabled: true,
          hint: '次数 ${snapshot.exploreCharges}/$maxExploreCharges',
        );
      case PetAction.clean:
        if (snapshot.poop <= 0 && snapshot.cleanliness > 94) {
          return const PetActionRule(enabled: false, hint: '暂时不需要清洁');
        }
        return const PetActionRule(enabled: true, hint: '清理环境恢复卫生');
      case PetAction.rest:
        if (snapshot.sleeping) {
          return const PetActionRule(enabled: false, hint: '已经在休息');
        }
        if (snapshot.energy > 90) {
          return const PetActionRule(enabled: false, hint: '现在还不困');
        }
        return const PetActionRule(enabled: true, hint: '进入睡眠恢复体力');
      case PetAction.battle:
        if (species.stage.index < PetStage.rookie.index) {
          return const PetActionRule(enabled: false, hint: '成长期后才能战斗');
        }
        if (snapshot.energy < 40) {
          return const PetActionRule(enabled: false, hint: '体力不足');
        }
        if (snapshot.battleCharges <= 0) {
          final remaining = battleRefillRemaining(snapshot, now);
          return PetActionRule(
            enabled: false,
            hint: '门票恢复 ${formatDuration(remaining ?? Duration.zero)}',
          );
        }
        return PetActionRule(
          enabled: true,
          hint: '门票 ${snapshot.battleCharges}/$maxBattleCharges',
        );
      case PetAction.praise:
        return const PetActionRule(enabled: true, hint: '增加心情和纪律');
      case PetAction.medicine:
        if (!snapshot.sick) {
          return const PetActionRule(enabled: false, hint: '现在没有生病');
        }
        return const PetActionRule(enabled: true, hint: '解除生病状态');
      case PetAction.hatch:
      case PetAction.restart:
        return const PetActionRule(enabled: true, hint: '');
    }
  }

  Duration? cooldownRemaining(PetSnapshot snapshot, PetAction action, DateTime now) {
    final readyAt = snapshot.cooldowns[action.name];
    if (readyAt == null || !readyAt.isAfter(now)) return null;
    return readyAt.difference(now);
  }

  Duration? hatchRemaining(PetSnapshot snapshot, DateTime now) {
    final species = speciesOf(snapshot);
    if (species.stage != PetStage.egg) return null;
    if (!snapshot.hatchReadyAt.isAfter(now)) return Duration.zero;
    return snapshot.hatchReadyAt.difference(now);
  }

  Duration? exploreRefillRemaining(PetSnapshot snapshot, DateTime now) {
    if (snapshot.exploreCharges >= maxExploreCharges) return null;
    final elapsed = now.difference(snapshot.lastExploreChargeAt);
    final progress = elapsed.isNegative ? Duration.zero : elapsed;
    final remain = exploreRefill - progress;
    return remain.isNegative ? Duration.zero : remain;
  }

  Duration? battleRefillRemaining(PetSnapshot snapshot, DateTime now) {
    if (snapshot.battleCharges >= maxBattleCharges) return null;
    final elapsed = now.difference(snapshot.lastBattleChargeAt);
    final progress = elapsed.isNegative ? Duration.zero : elapsed;
    final remain = battleRefill - progress;
    return remain.isNegative ? Duration.zero : remain;
  }

  PetSnapshot applyAction(PetSnapshot current, PetAction action, DateTime now) {
    final resolved = resolveTime(current, now);
    final rule = actionRule(resolved, action, now);
    if (!rule.enabled) {
      return _pushLog(
        resolved.copyWith(eventText: rule.hint, lastAction: action),
        '${actionLabels[action]}失败: ${rule.hint}',
      );
    }

    if (action == PetAction.restart) {
      return PetSnapshot.initial(
        now: now,
        discovered: resolved.discovered,
        usedCodes: resolved.usedCodes,
        unlockedBackgroundIds: resolved.unlockedBackgroundIds,
        activeBackgroundId: resolved.activeBackgroundId,
      ).copyWith(
        logs: [
          '重启舱已执行，新的数码蛋正在孵化。',
          ...resolved.logs.take(3),
        ],
      );
    }

    var next = resolved.copyWith(lastAction: action);

    if (action == PetAction.hatch) {
      next = _handleHatch(next, now);
    } else if (action == PetAction.feed) {
      next = _withCooldown(_handleFeed(next), action, now);
    } else if (action == PetAction.train) {
      next = _withCooldown(_handleTrain(next), action, now);
    } else if (action == PetAction.explore) {
      next = _withCooldown(_handleExplore(next, now), action, now);
    } else if (action == PetAction.clean) {
      next = _withCooldown(_handleClean(next), action, now);
    } else if (action == PetAction.rest) {
      next = _withCooldown(_handleRest(next, now), action, now);
    } else if (action == PetAction.battle) {
      next = _withCooldown(_handleBattle(next, now), action, now);
    } else if (action == PetAction.praise) {
      next = _withCooldown(_handlePraise(next), action, now);
    } else if (action == PetAction.medicine) {
      next = _withCooldown(_handleMedicine(next), action, now);
    }

    if (_needsSickness(next)) {
      next = next.copyWith(sick: true, eventText: '状态不佳');
    }

    if (_needsFailure(next)) {
      next = next.copyWith(careMistakes: next.careMistakes + 1);
    }

    if (next.careMistakes >= 8) {
      next = _pushLog(
        next.copyWith(alive: false, eventText: '已离开'),
        '照顾失误太多了，它没能坚持下来。',
      );
    }

    return _evolveIfNeeded(next);
  }

  PetSnapshot applySecretCode(PetSnapshot current, String rawCode, DateTime now) {
    final resolved = resolveTime(current, now);
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      return _pushLog(resolved.copyWith(eventText: '未输入秘码'), '你什么都没有输入。');
    }
    if (resolved.usedCodes.contains(code)) {
      return _pushLog(resolved.copyWith(eventText: '秘码失效'), '这个秘码已经使用过了。');
    }

    final usedCodes = [...resolved.usedCodes, code];
    switch (code) {
      case 'HATCH-777':
        return _pushLog(
          resolved.copyWith(
            hatchReadyAt: now,
            usedCodes: usedCodes,
            eventText: '孵化加速',
          ),
          '秘码生效，蛋壳开始发光，孵化时间被提前了。',
        );
      case 'PROTO-MON':
        return _pushLog(
          resolved.copyWith(
            usedCodes: usedCodes,
            forcedNextSpeciesId: 'cipher',
            eventText: '隐藏胚体写入',
          ),
          '秘码生效，下一次孵化将出现隐藏系宠物。',
        );
      case 'OVERCLOCK':
        return _pushLog(
          resolved.copyWith(
            usedCodes: usedCodes,
            cooldowns: const {},
            exploreCharges: maxExploreCharges,
            battleCharges: maxBattleCharges,
            lastExploreChargeAt: now,
            lastBattleChargeAt: now,
            energy: _clamp(resolved.energy + 12),
            moodValue: _clamp(resolved.moodValue + 8),
            eventText: '规则越限',
          ),
          '秘码生效，冷却与次数限制暂时被打破了。',
        );
      case 'RESET-KEY':
        return _pushLog(
          resolved.copyWith(
            usedCodes: usedCodes,
            restartUnlocked: true,
            eventText: '重启权限已解锁',
          ),
          '秘码生效，你获得了一次安全重置权限。',
        );
      default:
        return _pushLog(
          resolved.copyWith(eventText: '秘码无效'),
          '秘码没有反应，也许你输错了。',
        );
    }
  }

  PetSnapshot _handleHatch(PetSnapshot state, DateTime now) {
    final forced = state.forcedNextSpeciesId;
    final baby = forced != null ? speciesById[forced]! : _pickBaby();
    return _pushLog(
      state.copyWith(
        speciesId: baby.id,
        age: 0,
        discovered: _remember(state.discovered, baby.id),
        forcedNextSpeciesId: null,
        lastDecayAt: now,
        eventText: '破壳成功',
      ),
      '蛋壳裂开了，你得到了 ${baby.name}。',
    );
  }

  PetSnapshot _handleFeed(PetSnapshot state) {
    if (state.hunger > 85) {
      return _pushLog(
        state.copyWith(
          hunger: _clamp(state.hunger + 6),
          cleanliness: _clamp(state.cleanliness - 10),
          moodValue: _clamp(state.moodValue - 4),
          energy: _clamp(state.energy - 4),
          poop: state.poop + 1,
          eventText: '吃撑了',
        ),
        '它其实已经很饱了，硬喂让它有点不舒服。',
      );
    }
    return _pushLog(
      state.copyWith(
        hunger: _clamp(state.hunger + 22),
        moodValue: _clamp(state.moodValue + 7),
        poop: state.poop + 1,
        eventText: '吃得很香',
      ),
      '你喂了它一顿，它立刻开心起来了。',
    );
  }

  PetSnapshot _handleTrain(PetSnapshot state) {
    return _pushLog(
      state.copyWith(
        power: _clamp(state.power + 12),
        discipline: _clamp(state.discipline + 9),
        energy: _clamp(state.energy - 18),
        hunger: _clamp(state.hunger - 10),
        moodValue: _clamp(state.moodValue + 4),
        eventText: '完成训练',
      ),
      '训练结束，战力和纪律都提升了。',
    );
  }

  PetSnapshot _handleExplore(PetSnapshot state, DateTime now) {
    final roll = _random.nextDouble();
    var next = state.copyWith(
      exploreCharges: max(0, state.exploreCharges - 1),
      energy: _clamp(state.energy - 10),
      hunger: _clamp(state.hunger - 7),
      lastExploreChargeAt: state.exploreCharges >= maxExploreCharges ? now : state.lastExploreChargeAt,
    );

    if (roll > 0.75) {
      next = _pushLog(
        next.copyWith(
          power: _clamp(next.power + 10),
          moodValue: _clamp(next.moodValue + 8),
          eventText: '发现宝箱',
        ),
        '探索时发现了训练芯片，战力上升。',
      );
    } else if (roll > 0.45) {
      next = _pushLog(
        next.copyWith(
          wins: next.wins + 1,
          cleanliness: _clamp(next.cleanliness - 8),
          eventText: '遭遇野怪',
        ),
        '路上碰到野生小怪，打赢了一场遭遇战。',
      );
    } else {
      next = _pushLog(
        next.copyWith(
          moodValue: _clamp(next.moodValue + 8),
          eventText: '找到美景',
        ),
        '它一路看了很多新鲜东西，回来以后心情很好。',
      );
    }
    return next.copyWith(lastExploreChargeAt: now);
  }

  PetSnapshot _handleClean(PetSnapshot state) {
    return _pushLog(
      state.copyWith(
        poop: 0,
        cleanliness: _clamp(state.cleanliness + 36),
        moodValue: _clamp(state.moodValue + 5),
        eventText: '整理环境',
      ),
      '你把环境收拾干净了，它舒服多了。',
    );
  }

  PetSnapshot _handleRest(PetSnapshot state, DateTime now) {
    return _pushLog(
      state.copyWith(
        sleeping: true,
        sleepEndsAt: now.add(const Duration(minutes: 30)),
        energy: _clamp(state.energy + 8),
        eventText: '准备睡觉',
      ),
      '它缩成一团开始休息了。',
    );
  }

  PetSnapshot _handleBattle(PetSnapshot state, DateTime now) {
    final score = state.power + state.energy * 0.3 + state.moodValue * 0.2 + _random.nextDouble() * 25;
    var next = state.copyWith(
      battleCharges: max(0, state.battleCharges - 1),
      lastBattleChargeAt: now,
    );
    if (score > 75) {
      return _pushLog(
        next.copyWith(
          wins: next.wins + 1,
          power: _clamp(next.power + 8),
          moodValue: _clamp(next.moodValue + 12),
          energy: _clamp(next.energy - 10),
          eventText: '战斗胜利',
        ),
        '战斗获胜，它高兴得原地蹦了两下。',
      );
    }
    return _pushLog(
      next.copyWith(
        energy: _clamp(next.energy - 20),
        moodValue: _clamp(next.moodValue - 10),
        cleanliness: _clamp(next.cleanliness - 6),
        eventText: '战斗失败',
      ),
      '战斗输了，不过它还想继续努力。',
    );
  }

  PetSnapshot _handlePraise(PetSnapshot state) {
    return _pushLog(
      state.copyWith(
        moodValue: _clamp(state.moodValue + 12),
        discipline: _clamp(state.discipline + 6),
        eventText: '获得夸奖',
      ),
      '你摸了摸它，它看起来更信任你了。',
    );
  }

  PetSnapshot _handleMedicine(PetSnapshot state) {
    return _pushLog(
      state.copyWith(
        sick: false,
        moodValue: _clamp(state.moodValue + 4),
        eventText: '吃了药',
      ),
      '吃下药以后，它慢慢恢复了精神。',
    );
  }

  PetSnapshot _evolveIfNeeded(PetSnapshot current) {
    final species = speciesOf(current);
    if (!current.alive) return current;

    if (species.stage == PetStage.baby &&
        current.age >= 12 &&
        current.power >= 28 &&
        current.discipline >= 35) {
      final evolved = _pickRookie(current);
      return _pushLog(
        current.copyWith(
          speciesId: evolved.id,
          discovered: _remember(current.discovered, evolved.id),
          eventText: '进化',
        ),
        '${species.name} 进化成了 ${evolved.name}。',
      );
    }

    if (species.stage == PetStage.rookie &&
        current.age >= 30 &&
        current.power >= 60 &&
        current.wins >= 3) {
      final evolved = _pickChampion(current);
      return _pushLog(
        current.copyWith(
          speciesId: evolved.id,
          discovered: _remember(current.discovered, evolved.id),
          eventText: '进化',
        ),
        '${species.name} 爆发出光芒，进化成了 ${evolved.name}。',
      );
    }

    if (species.stage == PetStage.champion &&
        current.age >= 60 &&
        current.power >= 85 &&
        current.wins >= 8 &&
        current.careMistakes <= 3) {
      final evolved = _pickUltimate(current);
      return _pushLog(
        current.copyWith(
          speciesId: evolved.id,
          discovered: _remember(current.discovered, evolved.id),
          eventText: '究极进化',
        ),
        '${species.name} 成功突破极限，进化成了 ${evolved.name}。',
      );
    }

    return current;
  }

  PetSnapshot _refillCharges(PetSnapshot current, DateTime now) {
    var next = current;

    if (next.exploreCharges < maxExploreCharges && !now.isBefore(next.lastExploreChargeAt)) {
      final elapsed = now.difference(next.lastExploreChargeAt).inSeconds;
      final gained = elapsed ~/ exploreRefill.inSeconds;
      if (gained > 0) {
        final newCharges = min(maxExploreCharges, next.exploreCharges + gained);
        final missingBefore = maxExploreCharges - next.exploreCharges;
        final consumed = min(gained, missingBefore);
        next = next.copyWith(
          exploreCharges: newCharges,
          lastExploreChargeAt: newCharges == maxExploreCharges
              ? now
              : next.lastExploreChargeAt.add(
                  Duration(seconds: consumed * exploreRefill.inSeconds),
                ),
        );
      }
    } else if (next.exploreCharges >= maxExploreCharges) {
      next = next.copyWith(lastExploreChargeAt: now);
    }

    if (next.battleCharges < maxBattleCharges && !now.isBefore(next.lastBattleChargeAt)) {
      final elapsed = now.difference(next.lastBattleChargeAt).inSeconds;
      final gained = elapsed ~/ battleRefill.inSeconds;
      if (gained > 0) {
        final newCharges = min(maxBattleCharges, next.battleCharges + gained);
        final missingBefore = maxBattleCharges - next.battleCharges;
        final consumed = min(gained, missingBefore);
        next = next.copyWith(
          battleCharges: newCharges,
          lastBattleChargeAt: newCharges == maxBattleCharges
              ? now
              : next.lastBattleChargeAt.add(
                  Duration(seconds: consumed * battleRefill.inSeconds),
                ),
        );
      }
    } else if (next.battleCharges >= maxBattleCharges) {
      next = next.copyWith(lastBattleChargeAt: now);
    }

    return next;
  }

  PetSnapshot _withCooldown(PetSnapshot state, PetAction action, DateTime now) {
    final duration = actionCooldowns[action];
    if (duration == null) return state;
    final cooldowns = Map<String, DateTime>.from(state.cooldowns);
    cooldowns[action.name] = now.add(duration);
    return state.copyWith(cooldowns: cooldowns);
  }

  PetSpecies _pickBaby() {
    const options = ['bubble', 'mint', 'pearl', 'ember', 'sprout', 'gloom'];
    return speciesById[options[_random.nextInt(options.length)]]!;
  }

  PetSpecies _pickRookie(PetSnapshot state) {
    final species = speciesOf(state);
    if (species.line == '秘藏系') {
      return speciesById['glitch']!;
    }
    if (state.power >= 60 && state.wins >= 2) {
      return speciesById[state.cleanliness > 64 ? 'flare' : 'spark']!;
    }
    if (state.cleanliness >= 72 && state.discipline >= 50) {
      return speciesById[state.moodValue >= 65 ? 'moss' : 'tidal']!;
    }
    if (state.moodValue >= 75) {
      return speciesById[state.energy >= 55 ? 'glint' : 'sunbit']!;
    }
    return speciesById[state.cleanliness < 40 ? 'mist' : 'tidal']!;
  }

  PetSpecies _pickChampion(PetSnapshot state) {
    switch (speciesOf(state).line) {
      case '烈焰系':
        return speciesById['blaze']!;
      case '雷鸣系':
        return speciesById['thunder']!;
      case '森林系':
        return speciesById['bloom']!;
      case '深海系':
        return speciesById['reef']!;
      case '夜影系':
        return speciesById['dusk']!;
      case '秘藏系':
        return speciesById['sigil']!;
      case '星梦系':
      case '暖光系':
      default:
        return speciesById['aurora']!;
    }
  }

  PetSpecies _pickUltimate(PetSnapshot state) {
    switch (speciesOf(state).line) {
      case '烈焰系':
      case '星梦系':
        return speciesById['nova']!;
      case '森林系':
      case '夜影系':
        return speciesById['atlas']!;
      case '秘藏系':
        return speciesById['paradox']!;
      default:
        return speciesById['halo']!;
    }
  }

  bool _needsSickness(PetSnapshot state) => _criticalValues(state) >= 2;

  bool _needsFailure(PetSnapshot state) => state.poop >= 3 || _criticalValues(state) >= 3;

  int _criticalValues(PetSnapshot state) {
    final values = [
      state.hunger,
      state.moodValue,
      state.energy,
      state.cleanliness,
    ];
    return values.where((value) => value < 20).length;
  }

  List<String> _remember(List<String> discovered, String id) {
    if (discovered.contains(id)) return discovered;
    return [...discovered, id];
  }

  PetSnapshot _pushLog(PetSnapshot state, String text) {
    final updated = [text, ...state.logs];
    return state.copyWith(logs: updated.take(20).toList());
  }

  double _clamp(double value) => value.clamp(0, 100).toDouble();

  static String formatDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final minutes = safe.inMinutes;
    final seconds = safe.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
