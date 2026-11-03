class TableModel {
  String id;
  String name;
  String info;
  int colorValue;
  double top;
  double left;
  String spaceId;
  double scale;
  String? masterTableId;

  TableModel({
    required this.id,
    required this.name,
    this.info = '',
    required this.colorValue,
    required this.top,
    required this.left,
    required this.spaceId,
    this.scale = 1.0,
    this.masterTableId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'info': info,
        'colorValue': colorValue,
        'top': top,
        'left': left,
        'spaceId': spaceId,
        'scale': scale,
        'masterTableId': masterTableId,
      };

  factory TableModel.fromJson(Map<String, dynamic> json) => TableModel(
        id: json['id'],
        name: json['name'],
        info: json['info'] ?? '',
        colorValue: json['colorValue'],
        top: (json['top'] as num).toDouble(),
        left: (json['left'] as num).toDouble(),
        spaceId: json['spaceId'],
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        masterTableId: json['masterTableId'],
      );
}