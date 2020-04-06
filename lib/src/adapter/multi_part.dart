import '../http.dart';

import '_multi_part_for_native.dart'
if (dart.library.html) '_multi_part_for_html.dart' as _multipart;

import 'dart:io'
if (dart.library.html) 'dart:html' as _platform;


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
	MultipartDataBody addMultipartFile(String name,
		_platform.File file, {
			String fileName,
			String contentType,
		});
	
	/// 添加流 Multipart 数据
	/// - 在 Native 中，stream 为 Stream 对象
	/// - 在 Html 中，stream 对象为 Blob 对象
	MultipartDataBody addMultipartStream(String name, covariant dynamic stream, {String fileName, String contentType});
}
