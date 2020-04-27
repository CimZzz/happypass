import 'dart:math';

import '../request_body.dart';

import '_multi_part_for_native.dart'
if (dart.library.html) '_multi_part_for_html.dart' as _multipart;


/// Multipart 请求数据体
/// 对应使用的 Content-Type 为 'multipart/form-data'
/// 用来传递表单格式键值对数据
abstract class MultipartDataBody extends RequestBody {
	
	factory MultipartDataBody() => _multipart.MultipartDataBody();
	
	/// 是否覆盖请求头部中 `Content-Type` 字段
	/// 只有在请求头部中存在已指定的 `Content-Type` 字段时，该字段才会生效
	bool get overrideContentType => null;
	
	/// 请求数据的 Content-Type
	/// 当请求头中不包含 'Content-Type' 或者 [overrideContentType] 为 true 时，
	/// 该值会填充到请求头部之中
	String get contentType;
	
	/// 生成请求 Body 数据
	/// 提供请求数据
	Stream<dynamic> provideBodyData();
	
	/// 添加文本 Multipart 数据
	MultipartDataBody addMultipartText(String name, String text, {String fileName, String contentType});
	
	/// 添加文件 Multipart 数据
	/// 注意，file 类型必须为 `File`，否则会抛出异常
	MultipartDataBody addMultipartFile(String name,
		covariant dynamic file, {
			String fileName,
			String contentType,
		});
	
	/// 添加流 Multipart 数据
	/// - 在 Native 中，stream 为 Stream 对象
	/// - 在 Html 中，stream 对象为 Blob 对象
	MultipartDataBody addMultipartStream(String name, covariant dynamic stream, {String fileName, String contentType});
}

final _baseStr = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

/// 生成随机的 Boundary 字符串
String randomBoundary() {
	final random = Random();
	var str = '';
	for (var i = 0; i < 15; i++) {
		var idx = random.nextInt(62);
		str += _baseStr[idx];
	}
	return str;
}

/// 获取缺省的 `ContentType`
String getDefaultContentType(String fileName) {
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


/// Multipart 子数据
class MultiData {
	MultiData({this.name, this.data, this.fileName, this.contentType});

	final String name;
	final Object data;
	final String fileName;
	final String contentType;
}