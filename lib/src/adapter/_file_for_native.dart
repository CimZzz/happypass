import 'dart:io';
import 'file.dart' as _file;

class FileWrapper implements _file.FileWrapper {
	
	FileWrapper(this.filePath);
	
	final String filePath;
	
	String _errMsg;
	
	@override
	String checkErrMsg() => _errMsg;
	
	@override
	String getFilePath() => filePath;
	
	@override
	Future<bool> saveFileData(Stream<List<int>> rawData) async {
		var file = File(filePath);
		IOSink ioSink;
		try {
			if(! await file.exists()) {
				file = await file.create(recursive: true);
				if(file == null) {
					return false;
				}
			}
			ioSink = file.openWrite();
			await ioSink.addStream(rawData);
			ioSink.flush();
			return true;
		}
		catch(e) {
			_errMsg = e.toString();
			return false;
		}
		finally {
			if(ioSink != null) {
				await ioSink.close();
			}
		}
	}

}