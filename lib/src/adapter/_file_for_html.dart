import 'dart:html';
import 'file.dart' as _file;

const kFileBuffSize = 2048;

class FileWrapper implements _file.FileWrapper {
	
	FileWrapper(String filePath) : file = null {
		this._errMsg = 'Unsupport create by file path';
	}
	
	FileWrapper.createByFile(this.file);
	
	final File file;
	
	String _errMsg;
	
	
	@override
	String checkErrMsg() => _errMsg;
	
	@override
	String getFilePath() {
		return file?.relativePath ?? '';
	}
	
	@override
	Future<bool> saveFileData(Stream<List<int>> rawData) async {
		throw UnsupportedError('Unsupport download');
	}
}