import 'dart:convert';
import 'dart:io';
import '../request_body.dart';
import 'multi_part.dart' as _multipart;


/// 获取文件名
String _getFileName(File file) {
	if (file == null) {
		return null;
	}

	String fileName;
	final idx = file.path.lastIndexOf(Platform.pathSeparator);
	if (idx != -1) {
		fileName = file.path.substring(idx + 1);
	} else {
		fileName = file.path;
	}

	return fileName;
}

class MultipartDataBody implements _multipart.MultipartDataBody {
	
	/// Multipart Boundary
	final String _multipartBoundary = '----DartFormBoundary${_multipart.randomBoundary()}';
	
	/// 强制覆盖请求中的 `ContentType`
	@override
	bool get overrideContentType => true;
	
	@override
	String get contentType => 'multipart/form-data; boundary=$_multipartBoundary';
	
	/// Multipart 数据列表
	List<_multipart.MultiData> _multiDataList;
	
	/// 直接添加 Multipart 数据
	MultipartDataBody addMultiPartData(_multipart.MultiData data) {
		if (data == null) {
			return this;
		}
		
		_multiDataList ??= [];
		_multiDataList.add(data);
		return this;
	}
	/// 添加文本 Multipart 数据
	MultipartDataBody addMultipartText(String name, String text, {String fileName, String contentType}) {
		return addMultiPartData(_multipart.MultiData(name: name, data: text, fileName: fileName, contentType: _multipart.getDefaultContentType(fileName)));
	}
	
	/// 添加文件 Multipart 数据
	MultipartDataBody addMultipartFile(String name,
		File file, {
			String fileName,
			String contentType,
		}) {
		return addMultipartStream(name, file.openRead(), fileName: fileName ?? _getFileName(file), contentType: contentType);
	}
	
	/// 添加流 Multipart 数据
	MultipartDataBody addMultipartStream(String name, dynamic stream, {String fileName, String contentType}) {
		if (stream is Stream<List<int>>) {
			return addMultiPartData(_multipart.MultiData(
				name: name,
				data: stream,
				fileName: fileName,
				contentType: contentType ?? _multipart.getDefaultContentType(fileName),
			));
		}
		
		return this;
	}

	/// 提供请求 Body 数据
	@override
	Stream<dynamic> provideBodyData() async* {
		final multiDataList = _multiDataList;
		if (multiDataList == null) {
			yield null;
		}
		final length = multiDataList.length;
		for (var i = 0; i < length; i++) {
			final multiData = multiDataList[i];
			var contentHeader = '--$_multipartBoundary\r\nContent-Disposition: form-data; name=\"${multiData.name}\"';
			if (multiData.fileName != null) {
				contentHeader += '; filename=\"${multiData.fileName}\"';
			}
			contentHeader += '\r\n';
			if (multiData.data is Stream) {
				contentHeader += 'Content-Type: ${multiData.contentType ?? false}\r\n';
			}
			contentHeader += '\r\n';
			yield RawBodyData(rawData: utf8.encode(contentHeader));
			if (multiData.data is Stream) {
				yield* multiData.data;
			} else {
				yield multiData.data;
			}
			yield RawBodyData(rawData: utf8.encode('\r\n'));
		}
		yield RawBodyData(rawData: utf8.encode('--$_multipartBoundary--'));
	}
	
}