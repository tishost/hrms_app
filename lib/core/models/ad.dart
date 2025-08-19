class Ad {
  final int id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? url;
  final int displayOrder;
  final bool isClickable;
  final String? startDate;
  final String? endDate;

  Ad({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.url,
    required this.displayOrder,
    required this.isClickable,
    this.startDate,
    this.endDate,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'] ?? '',
      url: json['url'],
      displayOrder: json['display_order'] ?? 0,
      isClickable: json['is_clickable'] ?? false,
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'url': url,
      'display_order': displayOrder,
      'is_clickable': isClickable,
      'start_date': startDate,
      'end_date': endDate,
    };
  }

  @override
  String toString() {
    return 'Ad(id: $id, title: $title, imageUrl: $imageUrl, isClickable: $isClickable)';
  }
}
