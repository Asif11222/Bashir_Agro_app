/// Selects the same illustrated work icon for farmer and owner task cards.
/// Uses the task template's name/category, never submitted evidence photos.
class TaskThumbnailResolver {
  const TaskThumbnailResolver._();

  static String resolve({String? category, String? name}) {
    final cat = (category ?? '').toLowerCase();
    final taskName = (name ?? '').toLowerCase();

    if (cat.contains('মাছ') ||
        cat.contains('fish') ||
        taskName.contains('মাছ') ||
        taskName.contains('পুকুর')) {
      return 'fish';
    }
    if (cat.contains('ডেইরি') ||
        cat.contains('গরু') ||
        cat.contains('cow') ||
        cat.contains('পশু') ||
        taskName.contains('দুধ') ||
        taskName.contains('খামার')) {
      return 'cow';
    }
    if (taskName.contains('সার') ||
        cat.contains('সার') ||
        taskName.contains('fertilizer')) {
      return 'fertilizer';
    }
    return 'vegetable';
  }
}
