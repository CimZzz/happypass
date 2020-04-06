import '_file_for_native.dart'
if (dart.library.html) '_file_for_html.dart' as _file;

import 'dart:io'
if (dart.library.html) 'dart:html' as _platform;

abstract class FileWrapper {
	factory FileWrapper(String filePath) => _file.FileWrapper(filePath);
	
	factory FileWrapper.createByFile(_platform.File file) =>
		_file.FileWrapper.createByFile(file);
	
	String checkErrMsg();
	
	String getFilePath();
	
	Future<bool> saveFileData(Stream<List<int>> rawData);
}