import '_multi_part_for_native.dart'
if (dart.library.html) '_multi_part_for_html.dart' as _httpResponse;

import 'dart:io'
if (dart.library.html) 'dart:html' as _platform;

abstract class PassHttpResponse {
	
	/// 响应状态码
	int get statusCode;
	
	/// Content-Length
	int get contentLength;
	
	/// 数据流
	Stream<List<int>> get bodyStream;
	
	/// 获取 Http 响应头部
	String getResponseHeader(String key);
}