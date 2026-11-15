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
  });

  UserAccount copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? avatarIcon,
    UserRole? role,
    int? reputationPoints,
    bool? onboardingCompleted,
    bool? trustedDeviceEnabled,
  }) {
    return UserAccount(
      id: id,
      email: email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      role: role ?? this.role,
      reputationPoints: reputationPoints ?? this.reputationPoints,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      trustedDeviceEnabled: trustedDeviceEnabled ?? this.trustedDeviceEnabled,
      trustedDaysRemaining: trustedDaysRemaining,
    );
  }
}

enum CampaignMode { aoVivo, tempoLivre, agendada }

enum CampaignSegment { jogando, auxiliar, mestre, explorar }

class Campaign {
  final String id;
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

  const Campaign({
    required this.id,
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
  });

  String get modeBadge {
    switch (mode) {
      case CampaignMode.aoVivo:
        return 'AO VIVO';
      case CampaignMode.tempoLivre:
        return 'TEMPO LIVRE';
      case CampaignMode.agendada:
        return scheduleText.toUpperCase();
    }
  }
}

class HeroCharacter {
  final String id;
  final String name;
  final String heroClass;
  final String campaignTitle;
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

  const HeroCharacter({
    required this.id,
    required this.name,
    required this.heroClass,
    required this.campaignTitle,
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
  });
}

enum SystemSegment { oficiais, proprios, meus, comunidade }

class RpgSystem {
  final String id;
  final String name;
  final String version;
  final SystemSegment segment;
  final String diceEngine;
  final String description;
  final List<String> attributes;
  final int downloadsCount;
  final double rating;
  final bool isOfficial;

  const RpgSystem({
    required this.id,
    required this.name,
    required this.version,
    required this.segment,
    required this.diceEngine,
    required this.description,
    required this.attributes,
    required this.downloadsCount,
    required this.rating,
    required this.isOfficial,
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

class CompendiumItem {
  final String id;
  final String systemId;
  final CompendiumCategory category;
  final String name;
  final String rarity;
  final int slotsWeight;
  final String description;

  const CompendiumItem({
    required this.id,
    required this.systemId,
    required this.category,
    required this.name,
    required this.rarity,
    required this.slotsWeight,
    required this.description,
  });
}

class Guild {
  final String id;
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

  const Guild({
    required this.id,
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
  });

  ForumTopic copyWith({int? upvotes}) {
    return ForumTopic(
      id: id,
      authorHandle: authorHandle,
      category: category,
      title: title,
      content: content,
      upvotes: upvotes ?? this.upvotes,
      repliesCount: repliesCount,
      pinned: pinned,
      timeAgo: timeAgo,
    );
  }
}

class DiceRoll3d6 {
  final String label;
  final List<int> dice;
  final int successes;
  final String outcome;

  const DiceRoll3d6({
    required this.label,
    required this.dice,
    required this.successes,
    required this.outcome,
  });
}

class ChatMessage {
  final String id;
  final String channelId;
  final String senderHandle;
  final UserRole senderRole;
  final String content;
  final String timeText;
  final bool isMine;
  final bool isRead;
  final String? replyPreview;
  final DiceRoll3d6? diceRoll;

  const ChatMessage({
    required this.id,
    required this.channelId,
    required this.senderHandle,
    required this.senderRole,
    required this.content,
    required this.timeText,
    required this.isMine,
    required this.isRead,
    this.replyPreview,
    this.diceRoll,
  });
}

class FriendContact {
  final String id;
  final String username;
  final String displayName;
  final String presenceStatus;
  final String activity;
  final String lastDm;

  const FriendContact({
    required this.id,
    required this.username,
    required this.displayName,
    required this.presenceStatus,
    required this.activity,
    required this.lastDm,
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

  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.isRead,
    this.campaignCode,
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
    );
  }
}

class UniversalReport {
  final String id;
  final String originType;
  final String originId;
  final String reasonCategory;
  final String description;
  final List<String> autoTags;
  final String status;
  final String createdAtText;

  const UniversalReport({
    required this.id,
    required this.originType,
    required this.originId,
    required this.reasonCategory,
    required this.description,
    required this.autoTags,
    required this.status,
    required this.createdAtText,
  });

  UniversalReport copyWith({String? status}) {
    return UniversalReport(
      id: id,
      originType: originType,
      originId: originId,
      reasonCategory: reasonCategory,
      description: description,
      autoTags: autoTags,
      status: status ?? this.status,
      createdAtText: createdAtText,
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

