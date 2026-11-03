class Space {
  String id;
  String name;
  double? boundLeft;
  double? boundTop;
  double? boundWidth;
  double? boundHeight;

  Space({
    required this.id,
    required this.name,
    this.boundLeft,
    this.boundTop,
    this.boundWidth,
    this.boundHeight,
  });

  bool get hasBounds =>
      boundLeft != null &&
      boundTop != null &&
      boundWidth != null &&
      boundHeight != null &&
      boundWidth! >= 200.0 &&
      boundHeight! >= 200.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'boundLeft': boundLeft,
        'boundTop': boundTop,
        'boundWidth': boundWidth,
        'boundHeight': boundHeight,
      };

  factory Space.fromJson(Map<String, dynamic> json) => Space(
        id: json['id'],
        name: json['name'],
        boundLeft: (json['boundLeft'] as num?)?.toDouble(),
        boundTop: (json['boundTop'] as num?)?.toDouble(),
        boundWidth: (json['boundWidth'] as num?)?.toDouble(),
        boundHeight: (json['boundHeight'] as num?)?.toDouble(),
      );
}