import '_file_for_native.dart'
if (dart.library.html) '_file_for_html.dart' as _file;

abstract class FileWrapper {
	factory FileWrapper(String filePath) => _file.FileWrapper(filePath);
	
	String checkErrMsg();
	
	String getFilePath();
	
	Future<bool> saveFileData(Stream<List<int>> rawData);
}