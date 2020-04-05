import 'file.dart' as _file;


class FileWrapper implements _file.FileWrapper {
	
	FileWrapper(this.filePath);
	
	final String filePath;
	
	
	@override
	String checkErrMsg() => 'Unsupport download in html';
	
	@override
	String getFilePath() {
		throw UnsupportedError('Unsupport download');
	}
	
	@override
	Future<bool> saveFileData(Stream<List<int>> rawData) async {
		throw UnsupportedError('Unsupport download');
	}
}