import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:happypass/happypass.dart';

final _baseStr = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

/// 生成随机的 Boundary 字符串
String _randomBoundary() {
	final random = Random();
	var str = '';
	for (var i = 0; i < 15; i++) {
		var idx = random.nextInt(62);
		str += _baseStr[idx];
	}
	return str;
}

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

/// 获取缺省的 `ContentType`
String _getDefaultContentType(String fileName) {
	if (fileName == null) {
		return null;
	}

	final postfixIdx = fileName.lastIndexOf('.');
	if (postfixIdx == -1) {
		return null;
	}

	final postfix = fileName.substring(postfixIdx + 1);

	switch (postfix) {
		case 'txt':
			return 'text/plain';
		case 'jpeg':
			return 'image/jpeg';
		case 'jpg':
			return 'image/jpeg';
		case 'png':
			return 'image/png';
		case 'json':
			return 'application/json';
		case 'md':
			return 'text/markdown';
		case 'zip':
			return 'application/zip';
		case 'js':
			return 'text/javascript';
		case 'mp4':
			return 'video/mp4';
		default:
			return null;
	}
}

/// Multipart 每一个子数据
class MultiData {
	MultiData({this.name, this.data, this.fileName, this.contentType});

	final String name;
	final Object data;
	final String fileName;
	final String contentType;
}

/// Multipart 请求数据体
/// 对应使用的 Content-Type 为 'multipart/form-data'
/// 用来传递表单格式键值对数据
class MultipartDataBody extends RequestBody {
	/// Multipart Boundary
	final String _multipartBoundary = '----DartFormBoundary${_randomBoundary()}';

	/// 强制覆盖请求中的 `ContentType`
	@override
	bool get overrideContentType => true;

	@override
	String get contentType => 'multipart/form-data; boundary=$_multipartBoundary';

	/// Multipart 数据列表
	List<MultiData> _multiDataList;

	/// 直接添加 Multipart 数据
	MultipartDataBody addMultiPartData(MultiData data) {
		if (data == null) {
			return this;
		}

		_multiDataList ??= [];
		_multiDataList.add(data);
		return this;
	}

	/// 添加文本 Multipart 数据
	MultipartDataBody addMultipartText(String name, String text, {String fileName, String contentType}) {
		return addMultiPartData(MultiData(name: name, data: text, fileName: fileName, contentType: _getDefaultContentType(fileName)));
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
	MultipartDataBody addMultipartStream(String name, Stream<List<int>> stream, {String fileName, String contentType}) {
		return addMultiPartData(MultiData(
			name: name,
			data: stream,
			fileName: fileName,
			contentType: contentType ?? _getDefaultContentType(fileName),
		));
	}

	@override
	Stream<dynamic> provideBodyData() async* {
		final multiDataList = _multiDataList;
		if (multiDataList == null) {
			yield null;
		}

		final length = multiDataList.length;
		for (var i = 0; i < length; i++) {
			final multiData = multiDataList[i];
			var contentHeader = '--$_multipartBoundary\r\nContent-Disposition: form-data; name=\'${multiData.name}\'';
			if (multiData.fileName != null) {
				contentHeader += '; filename=\'${multiData.fileName}\'';
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
