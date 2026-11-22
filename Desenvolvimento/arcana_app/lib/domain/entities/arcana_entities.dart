import '../../core/security/rbac_guard.dart';

class UserAccount {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final String bio;
  final String avatarIcon;
  final UserRole role;
  final int reputationPoints;
  final bool onboardingCompleted;
  final bool trustedDeviceEnabled;
  final int trustedDaysRemaining;
  final Map<String, String> socialContacts;

  const UserAccount({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatarIcon,
    required this.role,
    required this.reputationPoints,
    required this.onboardingCompleted,
    required this.trustedDeviceEnabled,
    required this.trustedDaysRemaining,
    required this.socialContacts,
  });

  UserAccount copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? bio,
    String? avatarIcon,
    UserRole? role,
    int? reputationPoints,
    bool? onboardingCompleted,
    bool? trustedDeviceEnabled,
    int? trustedDaysRemaining,
    Map<String, String>? socialContacts,
  }) {
    return UserAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      role: role ?? this.role,
      reputationPoints: reputationPoints ?? this.reputationPoints,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      trustedDeviceEnabled: trustedDeviceEnabled ?? this.trustedDeviceEnabled,
      trustedDaysRemaining: trustedDaysRemaining ?? this.trustedDaysRemaining,
      socialContacts: socialContacts ?? this.socialContacts,
    );
  }
}

enum CampaignMode { aoVivo, tempoLivre, agendada }

enum CampaignSegment { jogando, auxiliar, mestre, explorar }

class WorldClockState {
  final int year;
  final int month;
  final String monthName;
  final int day;
  final int hour;
  final int minute;
  final String season;
  final int dayHours;
  final int daysPerMonth;
  final int lightHours;
  final List<String> months;
  final List<Map<String, dynamic>> events;

  const WorldClockState({
    this.year = 1,
    this.month = 1,
    this.monthName = 'Primeiro Ciclo',
    this.day = 1,
    this.hour = 8,
    this.minute = 0,
    this.season = 'Primavera',
    this.dayHours = 24,
    this.daysPerMonth = 30,
    this.lightHours = 12,
    this.months = const ['Primeiro Ciclo'],
    this.events = const [],
  });

  factory WorldClockState.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const WorldClockState();
    return WorldClockState(
      year: (json['year'] as num?)?.toInt() ?? 1,
      month: (json['month'] as num?)?.toInt() ?? 1,
      monthName: json['month_name']?.toString() ?? 'Primeiro Ciclo',
      day: (json['day'] as num?)?.toInt() ?? 1,
      hour: (json['hour'] as num?)?.toInt() ?? 8,
      minute: (json['minute'] as num?)?.toInt() ?? 0,
      season: json['season']?.toString() ?? 'Primavera',
      dayHours: (json['day_hours'] as num?)?.toInt() ?? 24,
      daysPerMonth: (json['days_per_month'] as num?)?.toInt() ?? 30,
      lightHours: (json['light_hours'] as num?)?.toInt() ?? 12,
      months: (json['months'] as List<dynamic>? ?? const ['Primeiro Ciclo'])
          .map((e) => e.toString())
          .toList(),
      events: (json['events'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'month_name': monthName,
        'day': day,
        'hour': hour,
        'minute': minute,
        'season': season,
        'day_hours': dayHours,
        'days_per_month': daysPerMonth,
        'light_hours': lightHours,
        'months': months,
        'events': events,
      };

  WorldClockState advanceHours(int delta) {
    final totalH = hour + delta;
    final addDays = totalH ~/ dayHours;
    final nextH = totalH % dayHours;
    var nextDay = day + addDays;
    var nextMonth = month;
    var nextYear = year;
    while (nextDay > daysPerMonth) {
      nextDay -= daysPerMonth;
      nextMonth += 1;
      if (nextMonth > months.length) {
        nextMonth = 1;
        nextYear += 1;
      }
    }
    final nextMonthName = months[(nextMonth - 1).clamp(0, months.length - 1)];
    return WorldClockState(
      year: nextYear,
      month: nextMonth,
      monthName: nextMonthName,
      day: nextDay,
      hour: nextH,
      minute: minute,
      season: season,
      dayHours: dayHours,
      daysPerMonth: daysPerMonth,
      lightHours: lightHours,
      months: months,
      events: events,
    );
  }

  bool get isDaylight => hour >= 6 && hour < (6 + lightHours);
}

class FactionEntry {
  final String id;
  final String name;
  final int reputation; // -100 a +100
  final String notes;

  const FactionEntry({
    required this.id,
    required this.name,
    required this.reputation,
    this.notes = '',
  });

  factory FactionEntry.fromJson(Map<String, dynamic> json) => FactionEntry(
        id: json['id']?.toString() ?? 'fac_1',
        name: json['name']?.toString() ?? 'Faccao',
        reputation: ((json['reputation'] as num?)?.toInt() ?? 0).clamp(-100, 100),
        notes: json['notes']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'reputation': reputation,
        'notes': notes,
      };
}

class DiaryEntry {
  final String id;
  final String scope; // cronica | pessoal | segredo_gm | roteiro
  final String title;
  final String content;
  final bool visibleToPlayers;
  final String authorId;
  final String createdAt;

  const DiaryEntry({
    required this.id,
    required this.scope,
    required this.title,
    required this.content,
    this.visibleToPlayers = true,
    this.authorId = '',
    this.createdAt = '',
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: json['id']?.toString() ?? 'dia_1',
        scope: json['scope']?.toString() ?? 'cronica',
        title: json['title']?.toString() ?? 'Entrada',
        content: json['content']?.toString() ?? '',
        visibleToPlayers: json['visible_to_players'] as bool? ?? true,
        authorId: json['author_id']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'scope': scope,
        'title': title,
        'content': content,
        'visible_to_players': visibleToPlayers,
        'author_id': authorId,
        'created_at': createdAt,
      };
}

class WorldMapEntry {
  final String id;
  final String name;
  final List<Map<String, dynamic>> pins; // [{q, r, title, terrain, colorHex}]

  const WorldMapEntry({
    required this.id,
    required this.name,
    this.pins = const [],
  });

  factory WorldMapEntry.fromJson(Map<String, dynamic> json) => WorldMapEntry(
        id: json['id']?.toString() ?? 'wmap_1',
        name: json['name']?.toString() ?? 'Regiao Central',
        pins: (json['pins'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pins': pins,
      };
}

class Campaign {
  final String id;
  final String ownerId;
  final String title;
  final String synopsis;
  final String masterHandle;
  final String systemId;
  final String systemName;
  final String quickJoinCode;
  final CampaignMode mode;
  final String scheduleText;
  final int maxSlots;
  final int occupiedSlots;
  final CampaignSegment userRelation;
  final String chapterTitle;
  final bool isPublic;
  final String iconName;
  final String bannerPreset;
  final String ageRating;
  final List<String> tags;
  final int sessionsCount;
  final String noticeBoard;
  final bool autoApproveActions;
  final String sceneAccessMode; // free | lock_step
  final double xpMultiplier;
  final String discordVoiceUrl;
  final String discordWebhookUrl;
  final bool isInactiveArchived;
  final List<String> channels;
  final WorldClockState worldClock;
  final List<FactionEntry> factions;
  final List<WorldMapEntry> worldMaps;
  final List<DiaryEntry> diaryEntries;

  const Campaign({
    required this.id,
    this.ownerId = '',
    required this.title,
    required this.synopsis,
    required this.masterHandle,
    required this.systemId,
    required this.systemName,
    required this.quickJoinCode,
    required this.mode,
    required this.scheduleText,
    required this.maxSlots,
    required this.occupiedSlots,
    required this.userRelation,
    required this.chapterTitle,
    required this.isPublic,
    this.iconName = 'swords',
    this.bannerPreset = 'cidadela_obsidiana',
    this.ageRating = '16+',
    this.tags = const [],
    this.sessionsCount = 0,
    this.noticeBoard = 'Bem-vindos a mesa! Aguardem as instrucoes do Mestre.',
    this.autoApproveActions = false,
    this.sceneAccessMode = 'free',
    this.xpMultiplier = 1.0,
    this.discordVoiceUrl = '',
    this.discordWebhookUrl = '',
    this.isInactiveArchived = false,
    this.channels = const ['#geral-mesa', '#off-topic', '#segredos-sussurros'],
    this.worldClock = const WorldClockState(),
    this.factions = const [],
    this.worldMaps = const [],
    this.diaryEntries = const [],
  });

  String get modeBadge {
    switch (mode) {
      case CampaignMode.aoVivo:
        return 'AO VIVO';
      case CampaignMode.tempoLivre:
        return 'FREE TIME';
      case CampaignMode.agendada:
        return 'AGENDADA';
    }
  }
}

class HeroCharacter {
  final String id;
  final String campaignId;
  final String name;
  final String heroClass;
  final String campaignTitle;
  final String systemId;
  final int level;
  final int hpCurrent;
  final int hpMax;
  final int animaCurrent;
  final int animaMax;
  final int exhaustion;
  final int corpo;
  final int mente;
  final int espirito;
  final List<String> slots;
  final Map<String, int> attributesMap;
  final Map<String, int> resourcesMap;
  final Map<String, String> equippedSlotsMap;
  final List<String> specializations;
  final int silverCoins;
  final String wealthTier;
  final List<String> powers;
  final List<String> contacts;
  final String lore;
  final int xpCurrent;

  const HeroCharacter({
    required this.id,
    required this.campaignId,
    required this.name,
    required this.heroClass,
    required this.campaignTitle,
    this.systemId = 'sys_universal',
    required this.level,
    required this.hpCurrent,
    required this.hpMax,
    required this.animaCurrent,
    required this.animaMax,
    required this.exhaustion,
    required this.corpo,
    required this.mente,
    required this.espirito,
    required this.slots,
    this.attributesMap = const {},
    this.resourcesMap = const {},
    this.equippedSlotsMap = const {},
    this.specializations = const [],
    this.silverCoins = 25,
    this.wealthTier = 'Comum',
    this.powers = const [],
    this.contacts = const [],
    this.lore = '',
    this.xpCurrent = 0,
  });
}

class CampaignLookupResult {
  final Campaign campaign;
  final bool isMember;
  final String membershipStatus; // none | pending | active | rejected

  const CampaignLookupResult({
    required this.campaign,
    required this.isMember,
    required this.membershipStatus,
  });
}

class CampaignMemberSummary {
  final String campaignId;
  final String userId;
  final String username;
  final String displayName;
  final String tableRole; // jogador | assistente_mestre | mestre
  final String status; // pending | active | rejected
  final String applicationPitch;

  const CampaignMemberSummary({
    required this.campaignId,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.tableRole,
    required this.status,
    required this.applicationPitch,
  });
}

class AdminUserSummary {
  final String id;
  final String email;
  final String birthDate;
  final UserRole role;
  final String accountStatus;
  final String username;
  final String displayName;
  final String? suspendedUntil;

  const AdminUserSummary({
    required this.id,
    required this.email,
    required this.birthDate,
    required this.role,
    required this.accountStatus,
    required this.username,
    required this.displayName,
    this.suspendedUntil,
  });

  AdminUserSummary copyWith({
    UserRole? role,
    String? accountStatus,
    String? suspendedUntil,
  }) {
    return AdminUserSummary(
      id: id,
      email: email,
      birthDate: birthDate,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      username: username,
      displayName: displayName,
      suspendedUntil: suspendedUntil ?? this.suspendedUntil,
    );
  }
}

class BannedDeviceSummary {
  final String deviceFingerprint;
  final String? userId;
  final String banReason;
  final String updatedAt;

  const BannedDeviceSummary({
    required this.deviceFingerprint,
    this.userId,
    required this.banReason,
    required this.updatedAt,
  });
}

class SystemCreationKey {
  final String code;
  final String createdBy;
  final String? assignedToUserId;
  final String? usedByUserId;
  final bool isUsed;
  final String createdAt;

  const SystemCreationKey({
    required this.code,
    required this.createdBy,
    this.assignedToUserId,
    this.usedByUserId,
    required this.isUsed,
    required this.createdAt,
  });
}

enum SystemSegment { oficiais, proprios, meus, comunidade }

class RpgSystem {
  final String id;
  final String authorId;
  final String name;
  final String version;
  final SystemSegment segment;
  final String diceEngine;
  final String description;
  final List<String> attributes;
  final int downloadsCount;
  final double rating;
  final bool isOfficial;
  final bool isFavorite;
  final bool isOfflineCached;

  const RpgSystem({
    required this.id,
    this.authorId = '',
    required this.name,
    required this.version,
    required this.segment,
    required this.diceEngine,
    required this.description,
    required this.attributes,
    required this.downloadsCount,
    required this.rating,
    required this.isOfficial,
    this.isFavorite = false,
    this.isOfflineCached = false,
  });
}

enum CompendiumCategory {
  itens,
  equipamentos,
  seres,
  poderes,
  pistas;

  String get labelPtBr {
    switch (this) {
      case CompendiumCategory.itens:
        return 'Itens';
      case CompendiumCategory.equipamentos:
        return 'Equipamentos';
      case CompendiumCategory.seres:
        return 'Seres';
      case CompendiumCategory.poderes:
        return 'Poderes';
      case CompendiumCategory.pistas:
        return 'Pistas';
    }
  }
}

class CompendiumBlock {
  final String id;
  final String label;
  final String value;
  final String? diceFormula;
  final int? parsedMin;
  final int? parsedMax;
  final String? targetVariableId;
  final String operation; // add | sub | set | info
  final bool isVisible; // RoleGate: false = oculto dos jogadores

  const CompendiumBlock({
    required this.id,
    required this.label,
    required this.value,
    this.diceFormula,
    this.parsedMin,
    this.parsedMax,
    this.targetVariableId,
    this.operation = 'info',
    this.isVisible = true,
  });

  factory CompendiumBlock.fromJson(String id, Map<String, dynamic> json) {
    final range = (json['parsed_range'] as Map?)?.cast<String, dynamic>();
    return CompendiumBlock(
      id: id,
      label: json['label']?.toString() ?? id,
      value: json['value']?.toString() ?? '',
      diceFormula: json['dice_formula']?.toString(),
      parsedMin: (range?['min'] as num?)?.toInt(),
      parsedMax: (range?['max'] as num?)?.toInt(),
      targetVariableId: json['target_variable_id']?.toString(),
      operation: json['operation']?.toString() ?? 'info',
      isVisible: json['is_visible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        if (diceFormula != null && diceFormula!.isNotEmpty) 'dice_formula': diceFormula,
        if (targetVariableId != null && targetVariableId!.isNotEmpty)
          'target_variable_id': targetVariableId,
        'operation': operation,
        'is_visible': isVisible,
      };
}

class CompendiumItem {
  final String id;
  final String systemId;
  final String? campaignId;
  final String? parentId;
  final CompendiumCategory category;
  final String name;
  final String rarity;
  final int slotsWeight;
  final String description;
  final String baseAssetId;
  final String? equipSlot;
  final bool isAllHidden;
  final String authorId;
  final List<CompendiumBlock> blocks;

  const CompendiumItem({
    required this.id,
    required this.systemId,
    this.campaignId,
    this.parentId,
    required this.category,
    required this.name,
    required this.rarity,
    required this.slotsWeight,
    required this.description,
    this.baseAssetId = 'shield',
    this.equipSlot,
    this.isAllHidden = false,
    this.authorId = '',
    this.blocks = const [],
  });
}

enum SceneModelType {
  grid2d,
  mahjong,
  password,
  dialogue,
  jrpgCombat,
  terminal;

  String get wireKey {
    switch (this) {
      case SceneModelType.grid2d:
        return 'grid_2d';
      case SceneModelType.mahjong:
        return 'mahjong';
      case SceneModelType.password:
        return 'password';
      case SceneModelType.dialogue:
        return 'dialogue';
      case SceneModelType.jrpgCombat:
        return 'jrpg_combat';
      case SceneModelType.terminal:
        return 'terminal';
    }
  }

  String get labelPtBr {
    switch (this) {
      case SceneModelType.grid2d:
        return '1. Grid Tatico 2D (Fog & Tokens)';
      case SceneModelType.mahjong:
        return '2. Tabuleiro Mahjong & Minas';
      case SceneModelType.password:
        return '3. Senha & Cofre (Pistas 3 Niveis)';
      case SceneModelType.dialogue:
        return '4. Menus & Dialogos Ramificados';
      case SceneModelType.jrpgCombat:
        return '5. Combate Tatico JRPG por Turnos';
      case SceneModelType.terminal:
        return '6. Terminal CRT & Console If-Then';
    }
  }

  static SceneModelType fromWire(String raw) {
    switch (raw) {
      case 'mahjong':
        return SceneModelType.mahjong;
      case 'password':
        return SceneModelType.password;
      case 'dialogue':
        return SceneModelType.dialogue;
      case 'jrpg_combat':
        return SceneModelType.jrpgCombat;
      case 'terminal':
        return SceneModelType.terminal;
      default:
        return SceneModelType.grid2d;
    }
  }
}

class CampaignScene {
  final String id;
  final String campaignId;
  final String name;
  final String description;
  final SceneModelType modelType;
  final bool isActive;
  final int maxPlayers;
  final Map<String, dynamic> modelData;
  final List<Map<String, dynamic>> rulesData;
  final Map<String, dynamic> stateData;

  const CampaignScene({
    required this.id,
    required this.campaignId,
    required this.name,
    required this.description,
    required this.modelType,
    this.isActive = false,
    this.maxPlayers = 12,
    this.modelData = const {},
    this.rulesData = const [],
    this.stateData = const {},
  });
}

class Guild {
  final String id;
  final String leaderId;
  final String name;
  final String tag;
  final String leaderHandle;
  final String description;
  final int memberCount;
  final int activeTablesCount;
  final int boostPoints;
  final int boostGoal;
  final String sharedWorldName;
  final String currentSeason;
  final int level;
  final int maxMembers;
  final int maxMasters;
  final int maxChannels;
  final int maxClans;
  final int maxCustomRoles;
  final List<Map<String, dynamic>> clans;
  final List<Map<String, dynamic>> wikiArticles;
  final List<String> channels;

  const Guild({
    required this.id,
    this.leaderId = '',
    required this.name,
    required this.tag,
    required this.leaderHandle,
    required this.description,
    required this.memberCount,
    required this.activeTablesCount,
    required this.boostPoints,
    required this.boostGoal,
    required this.sharedWorldName,
    required this.currentSeason,
    this.level = 1,
    this.maxMembers = 20,
    this.maxMasters = 2,
    this.maxChannels = 3,
    this.maxClans = 1,
    this.maxCustomRoles = 3,
    this.clans = const [],
    this.wikiArticles = const [],
    this.channels = const ['#taverna-guilda', '#world-wiki'],
  });
}

class ForumComment {
  final String id;
  final String topicId;
  final String authorHandle;
  final String content;
  final String timeAgo;

  const ForumComment({
    required this.id,
    required this.topicId,
    required this.authorHandle,
    required this.content,
    required this.timeAgo,
  });
}

class ForumTopic {
  final String id;
  final String authorHandle;
  final String category;
  final String title;
  final String content;
  final int upvotes;
  final int repliesCount;
  final bool pinned;
  final String timeAgo;
  final String createdAtIso;
  final List<ForumComment> comments;

  const ForumTopic({
    required this.id,
    required this.authorHandle,
    required this.category,
    required this.title,
    required this.content,
    required this.upvotes,
    required this.repliesCount,
    required this.pinned,
    required this.timeAgo,
    this.createdAtIso = '',
    this.comments = const [],
  });

  ForumTopic copyWith({
    int? upvotes,
    int? repliesCount,
    List<ForumComment>? comments,
  }) {
    return ForumTopic(
      id: id,
      authorHandle: authorHandle,
      category: category,
      title: title,
      content: content,
      upvotes: upvotes ?? this.upvotes,
      repliesCount: repliesCount ?? this.repliesCount,
      pinned: pinned,
      timeAgo: timeAgo,
      createdAtIso: createdAtIso,
      comments: comments ?? this.comments,
    );
  }
}

class DiceRoll3d6 {
  final String label;
  final List<int> dice;
  final int successes;
  final String outcome;
  final String expression;
  final int total;
  final String engine;
  final List<int> keptDice;

  const DiceRoll3d6({
    required this.label,
    required this.dice,
    required this.successes,
    required this.outcome,
    this.expression = '3d6',
    this.total = 0,
    this.engine = 'formula',
    this.keptDice = const [],
  });
}

class ChatMessage {
  final String id;
  final String channelId;
  final String senderId;
  final String senderHandle;
  final UserRole senderRole;
  final String content;
  final String timeText;
  final bool isMine;
  final bool isRead;
  final String? replyPreview;
  final DiceRoll3d6? diceRoll;
  final String msgType; // ic | ooc | narracao | acao | roll | gmroll | whisper | action_card | dm
  final String? npcName;
  final String? whisperTarget;
  final Map<String, dynamic>? actionCard;

  const ChatMessage({
    required this.id,
    required this.channelId,
    this.senderId = '',
    required this.senderHandle,
    required this.senderRole,
    required this.content,
    required this.timeText,
    required this.isMine,
    required this.isRead,
    this.replyPreview,
    this.diceRoll,
    this.msgType = 'ic',
    this.npcName,
    this.whisperTarget,
    this.actionCard,
  });
}

class FriendContact {
  final String id;
  final String username;
  final String displayName;
  final String presenceStatus;
  final String activity;
  final String lastDm;
  final String status; // pending | accepted | blocked
  final String avatarIcon;

  const FriendContact({
    required this.id,
    required this.username,
    required this.displayName,
    required this.presenceStatus,
    required this.activity,
    required this.lastDm,
    this.status = 'accepted',
    this.avatarIcon = 'user',
  });
}

class AppNotification {
  final String id;
  final String category; // mesas, social, sistema
  final String title;
  final String body;
  final String timeAgo;
  final bool isRead;
  final String? campaignCode;
  final String? campaignId;
  final String? inviteId;

  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.isRead,
    this.campaignCode,
    this.campaignId,
    this.inviteId,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      category: category,
      title: title,
      body: body,
      timeAgo: timeAgo,
      isRead: isRead ?? this.isRead,
      campaignCode: campaignCode,
      campaignId: campaignId,
      inviteId: inviteId,
    );
  }
}

class SocialProfileView {
  final String userId;
  final String username;
  final String displayName;
  final String bio;
  final String avatarIcon;
  final UserRole role;
  final bool oauthVerified;
  final int reputationPoints;
  final String createdAt;
  final Map<String, String> contacts;
  final List<Map<String, dynamic>> mutualCampaigns;
  final int campaignsAsPlayer;
  final int campaignsAsMaster;
  final int charactersCount;
  final List<Map<String, dynamic>> systemsRanked;
  final List<Map<String, dynamic>> campaignsList;
  final List<Map<String, dynamic>> charactersList;

  const SocialProfileView({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatarIcon,
    required this.role,
    this.oauthVerified = true,
    this.reputationPoints = 0,
    this.createdAt = '',
    this.contacts = const {},
    this.mutualCampaigns = const [],
    this.campaignsAsPlayer = 0,
    this.campaignsAsMaster = 0,
    this.charactersCount = 0,
    this.systemsRanked = const [],
    this.campaignsList = const [],
    this.charactersList = const [],
  });
}

class UniversalReport {
  final String id;
  final String originType;
  final String entityType;
  final String originId;
  final String? targetUserId;
  final String reasonCategory;
  final String description;
  final List<String> autoTags;
  final String status;
  final String createdAtText;
  final int votesCount;
  final int requiredVotes;

  const UniversalReport({
    required this.id,
    required this.originType,
    this.entityType = '',
    required this.originId,
    this.targetUserId,
    required this.reasonCategory,
    required this.description,
    required this.autoTags,
    required this.status,
    required this.createdAtText,
    this.votesCount = 0,
    this.requiredVotes = 3,
  });

  UniversalReport copyWith({
    String? status,
    int? votesCount,
  }) {
    return UniversalReport(
      id: id,
      originType: originType,
      entityType: entityType,
      originId: originId,
      targetUserId: targetUserId,
      reasonCategory: reasonCategory,
      description: description,
      autoTags: autoTags,
      status: status ?? this.status,
      createdAtText: createdAtText,
      votesCount: votesCount ?? this.votesCount,
      requiredVotes: requiredVotes,
    );
  }
}

class TutorialModule {
  final String id;
  final String title;
  final String subtitle;
  final bool completed;

  const TutorialModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.completed,
  });

  TutorialModule copyWith({bool? completed}) {
    return TutorialModule(
      id: id,
      title: title,
      subtitle: subtitle,
      completed: completed ?? this.completed,
    );
  }
}

class AudioMixerSettings {
  final double masterVolume;
  final double ambienceVolume;
  final double sfxVolume;
  final double voiceVolume;

  const AudioMixerSettings({
    required this.masterVolume,
    required this.ambienceVolume,
    required this.sfxVolume,
    required this.voiceVolume,
  });

  AudioMixerSettings copyWith({
    double? masterVolume,
    double? ambienceVolume,
    double? sfxVolume,
    double? voiceVolume,
  }) {
    return AudioMixerSettings(
      masterVolume: masterVolume ?? this.masterVolume,
      ambienceVolume: ambienceVolume ?? this.ambienceVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      voiceVolume: voiceVolume ?? this.voiceVolume,
    );
  }
}

class NewsItem {
  final String id;
  final String tag;
  final String title;
  final String summary;

  const NewsItem({
    required this.id,
    required this.tag,
    required this.title,
    required this.summary,
  });
}
