class StoreItem {
  const StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.creator,
    required this.installable,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final bool creator;
  final bool installable;

  factory StoreItem.fromJson(Map<String, dynamic> json) => StoreItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Unknown app',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'Apps',
        creator: json['creator'] as bool? ?? false,
        installable: json['installable'] as bool? ?? false,
      );
}
