import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum NoteCategory {
  meeting('Совещание', Icons.groups_outlined),
  assembly('Собрание', Icons.how_to_vote_outlined),
  conference('Конференция', Icons.mic_none_outlined),
  businessMeeting('Деловая встреча', Icons.handshake_outlined),
  other('Другое', Icons.sticky_note_2_outlined);

  const NoteCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static NoteCategory fromName(String? name) => NoteCategory.values
      .firstWhere((c) => c.name == name, orElse: () => NoteCategory.other);
}

class Note {
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.dateTime,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime dateTime;
  final NoteCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;

  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _timeFormat = DateFormat('HH:mm');

  String get dateKey => _dateFormat.format(dateTime);

  String get timeKey => _timeFormat.format(dateTime);

  Note copyWith({
    String? title,
    String? content,
    DateTime? dateTime,
    NoteCategory? category,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      dateTime: dateTime ?? this.dateTime,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'date': dateKey,
        'time': timeKey,
        'category': category.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, Object?> json) {
    final date = DateTime.parse(json['date'] as String);
    final timeParts = (json['time'] as String? ?? '00:00').split(':');
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      dateTime: DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      ),
      category: NoteCategory.fromName(json['category'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.id == id &&
      other.title == title &&
      other.content == content &&
      other.dateTime == dateTime &&
      other.category == category &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, title, content, dateTime, category, createdAt, updatedAt);
}
