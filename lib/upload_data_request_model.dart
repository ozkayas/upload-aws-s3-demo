class UploadData {
  final String url;
  final Map<String, String> fields;

  UploadData({
    required this.url,
    required this.fields,
  });

  factory UploadData.fromJson(Map<String, dynamic> json) {
    return UploadData(
      url: json['url'],
      fields: Map<String, String>.from(json['fields']),
    );
  }
}
