import 'package:http/http.dart' as http;

class NetworkService {
  Future<bool> uploadToS3({
    required String uploadUrl,
    required Map<String, String> data,
    required List<int> fileAsBinary,
    required String filename,
  }) async {
    var multiPartFile = http.MultipartFile.fromBytes('file', fileAsBinary, filename: filename);
    var uri = Uri.parse(uploadUrl);
    var request = http.MultipartRequest('POST', uri)
      ..fields.addAll(data)
      ..files.add(multiPartFile);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 204) {
      print('Uploaded!');
      return true;
    }
    return false;
  }
}
