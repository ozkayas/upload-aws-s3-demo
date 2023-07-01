import 'dart:io';
import 'dart:math';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:upload_with_presigned_url/network_service.dart';
import 'package:upload_with_presigned_url/upload_data_request_model.dart';

class UploadFileView extends StatefulWidget {
  const UploadFileView({super.key});

  @override
  State<UploadFileView> createState() => _UploadFileViewState();
}

class _UploadFileViewState extends State<UploadFileView> {
  bool isDragging = false;
  ValueNotifier<Object?> selectedFile = ValueNotifier<Object?>(null);

  //Network service should be injected in a real app
  NetworkService networkService = NetworkService();

  ///Sample data for uploadData, replace with your own data
  UploadData uploadData = UploadData(
    url: 'https://mytestbucket.s3.amazonaws.com/',
    fields: {
      "key": "inputdata/user1/myDataFile.xlsx",
      "AWSAccessKeyId": "ASIAABCXXXXXXXXXXXX",
      "x-amz-security-token": "abcxyzloremipsum",
      "policy": "abcxyzloremipsum",
      "signature": "abcxyzloremipsum",
    },
  );

  void uploadSelectedFile() async {
    final (selectedFileBytes, selectedFileName) = await getFileBytesAndName(selectedFile.value);

    await networkService.uploadToS3(
      uploadUrl: uploadData.url,
      data: uploadData.fields,
      fileAsBinary: selectedFileBytes,
      filename: selectedFileName,
    );
  }

  Future<(List<int>, String)> getFileBytesAndName(Object? file) async {
    List<int> bytes;
    String fileName;

    if (file is XFile) {
      bytes = await file.readAsBytes();
      fileName = file.name;
    } else if (file is PlatformFile) {
      if (kIsWeb) {
        bytes = file.bytes!;
      } else {
        bytes = await getFileBytes(file);
      }
      fileName = file.name;
    } else {
      throw Exception('Invalid file type');
    }
    return (bytes, fileName);
  }

  /// Get the file bytes from the PlatformFile object
  Future<List<int>> getFileBytes(PlatformFile platformFile) async {
    // Get the file path from the PlatformFile object
    String? filePath = platformFile.path;

    // Read the file as bytes, File is from the dart:io library
    File file = File(filePath!);
    List<int> fileBytes = await file.readAsBytes();

    return fileBytes;
  }

  // void fileUploadSuccessCallBack() {
  //   if (context.read<UploadFileProvider>().fileUploadSuccess.value) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           'File uploaded successfully',
  //           style: TextStyle(fontSize: 22),
  //         ),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //     context.read<UploadFileProvider>().clearSelectedFileData();
  //   }
  // }

  Future<void> _selectFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      dialogTitle: 'Select a file to upload',
      allowedExtensions: ['xls', 'xlsx', 'pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      final PlatformFile file = result.files.single;
      selectedFile.value = file;
    }
  }

  void _onDragDone(DropDoneDetails urls) async {
    final droppedFile = urls.files.first;
    final String selectedFileType = path.extension(droppedFile.name);

    //if the file type is not xls or xlsx, show scaffold error message
    if (selectedFileType != '.xls' && selectedFileType != '.xlsx') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid file type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    selectedFile.value = droppedFile;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final double boxWidth = min(width * 0.8, 500);
    return DropTarget(
      onDragDone: _onDragDone,
      onDragEntered: (_) => setState(() => isDragging = true),
      onDragExited: (_) => setState(() => isDragging = false),
      child: Container(
          height: 300,
          width: boxWidth,
          decoration: BoxDecoration(
            color: isDragging ? Colors.deepPurple.shade300 : Colors.deepPurple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.upload_file,
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Upload Data File',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Drag and drop your data file here',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'or',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: _selectFile,
                          child: const Text('Select File'),
                        ),
                        const SizedBox(width: 16),
                        ValueListenableBuilder<Object?>(
                          valueListenable: selectedFile,
                          builder: (context, file, _) {
                            final fileName = file is XFile
                                ? file.name
                                : file is PlatformFile
                                    ? file.name
                                    : "No file selected";
                            return Text(
                              fileName,
                              style: const TextStyle(color: Colors.deepPurple),
                            );
                          },
                        ),
                        const Text(
                          'No file selected',
                          style: TextStyle(color: Colors.deepPurple),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<Object?>(
                  valueListenable: selectedFile,
                  builder: (context, file, _) {
                    return ElevatedButton(
                      onPressed: file == null ? null : uploadSelectedFile,
                      child: const Text(
                        'Upload File',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<Object?>(
                  valueListenable: selectedFile,
                  builder: (context, file, _) {
                    return Text(
                      'Selected file Type: ${file.runtimeType}',
                      style: const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ],
            ),
          )),
    );
  }
}
