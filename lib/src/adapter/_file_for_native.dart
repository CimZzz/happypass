import 'dart:io';
import 'file.dart' as _file;

class FileWrapper implements _file.FileWrapper {
	
	FileWrapper(String filePath) : file = File(filePath);
	
	FileWrapper.createByFile(this.file);
	
	final File file;
	
	String _errMsg;
	
	@override
	String checkErrMsg() => _errMsg;
	
	@override
	String getFilePath() => file.path;
	
	@override
	Future<bool> saveFileData(Stream<List<int>> rawData) async {
		IOSink ioSink;
		File tempFile = file;
		try {
			if (!await tempFile.exists()) {
				tempFile = await tempFile.create(recursive: true);
				if (tempFile == null) {
					return false;
				}
			}
			ioSink = tempFile.openWrite();
			await ioSink.addStream(rawData);
			ioSink.flush();
			return true;
		}
		catch (e) {
			_errMsg = e.toString();
			return false;
		}
		finally {
			if (ioSink != null) {
				await ioSink.close();
			}
		}
	}
}