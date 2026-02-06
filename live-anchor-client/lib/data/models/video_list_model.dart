import 'package:flutter/material.dart';

/// video/getVideoList 接口单条数据
class VideoListItem {
  final int? videoId;
  final String? cover; // 封面图 URL
  final int? duration; // 时长（秒）
  final String? videoUrl;
  final String? introduction;
  final int? coin;
  final int? type; // 0: Daily, 1: Sexy（Say Hi 已隐藏）
  final int? auditStatus; // 审核状态 0:Approved 1:Not submitted 2:In review 3:Review failed

  VideoListItem({
    this.videoId,
    this.cover,
    this.duration,
    this.videoUrl,
    this.introduction,
    this.coin,
    this.type,
    this.auditStatus,
  });

  factory VideoListItem.fromJson(Map<String, dynamic> json) {
    return VideoListItem(
      videoId: json['videoId'] as int?,
      cover: json['cover'] as String?,
      duration: json['duration'] as int?,
      videoUrl: json['videoUrl'] as String?,
      introduction: json['introduction'] as String?,
      coin: json['coin'] as int?,
      type: json['type'] as int?,
      auditStatus: json['auditStatus'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'cover': cover ?? '',
      'duration': duration ?? 0,
      'videoUrl': videoUrl ?? '',
      'introduction': introduction ?? '',
      'coin': coin ?? 0,
      'type': type ?? 0,
      'auditStatus': auditStatus,
    };
  }

  /// 审核状态文案（与 Say Hi 一致）
  String get statusText {
    switch (auditStatus) {
      case 0:
        return 'Approved';
      case 1:
        return 'Not submitted';
      case 2:
        return 'In review';
      case 3:
        return 'Review failed';
      default:
        return 'Unknown';
    }
  }

  IconData get statusIcon {
    switch (auditStatus) {
      case 0:
        return Icons.check_circle;
      case 1:
        return Icons.info_outline;
      case 2:
        return Icons.access_time;
      case 3:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color get statusColor {
    switch (auditStatus) {
      case 0:
        return const Color(0xFF4CAF50);
      case 1:
        return Colors.grey;
      case 2:
        return Colors.orange;
      case 3:
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  /// 格式化为 mm:ss 时长
  String get durationText {
    final s = duration ?? 0;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
